package service

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/services/identity/models"
	"github.com/siteeksen/backend/services/identity/repository"
	"golang.org/x/crypto/bcrypt"
)

// ErrInvalidRoleInput görevlendirme girdisi geçersiz; mesaj kullanıcıya gösterilir.
var ErrInvalidRoleInput = errors.New("görevlendirme bilgisi geçersiz")

// siteRoles: verilebilen yönetim rolleri. Karar gerektirenler KMK m.34 (yönetici,
// yönetim kurulu) ve m.41 (denetçi) uyarınca kat malikleri kurulunca atanır;
// görevli (STAFF) bir işe alım kararıdır, karar bilgisi isteğe bağlıdır.
var siteRoles = map[string]bool{"MANAGER": true, "BOARD_MEMBER": true, "AUDITOR": true, "STAFF": true}
var rolesNeedingDecision = map[string]bool{"MANAGER": true, "BOARD_MEMBER": true, "AUDITOR": true}

// RoleRevoker, görevi sona eren kişinin açık oturumlarını kapatır.
type RoleRevoker interface {
	RevokeAll(ctx context.Context, userID, reason string) error
}

// RoleService site görevlendirmeleri.
//
// NEDEN (2026-10-03): property_roles'a yazan HİÇBİR uç yoktu. Kurucu dışında
// kimseye yönetici, kurul üyesi, denetçi ya da görevli rolü verilemiyordu;
// görevi biten birinin yetkisi de kaldırılamıyordu.
type RoleService struct {
	repo    *repository.RoleRepository
	auth    *AuthService
	revoker RoleRevoker
}

// NewRoleService servisi kurar.
func NewRoleService(repo *repository.RoleRepository, auth *AuthService, revoker RoleRevoker) *RoleService {
	return &RoleService{repo: repo, auth: auth, revoker: revoker}
}

// canManageRoles: yalnızca yönetici görevlendirir. Kurul üyesi sakin ekleyebilir
// ama yetki dağıtamaz (görevler ayrılığı; KMK m.34 atamayı kurula bırakır).
func canManageRoles(roles []string) bool {
	for _, r := range roles {
		if r == middleware.RoleManager {
			return true
		}
	}
	return false
}

// List sitenin görevlendirmelerini getirir (yönetim ve denetçi okur).
func (s *RoleService) List(ctx context.Context, propertyID string, roles []string) ([]*models.SiteRole, error) {
	if !canReadResidents(roles) {
		return nil, ErrResidentForbidden
	}
	return s.repo.List(ctx, propertyID)
}

func parseDay(v string) (time.Time, error) {
	return time.Parse("2006-01-02", strings.TrimSpace(v))
}

// Grant görev verir.
func (s *RoleService) Grant(ctx context.Context, propertyID, actorID string, roles []string, in models.GrantRoleInput) (*models.GrantRoleResult, error) {
	if !canManageRoles(roles) {
		return nil, ErrResidentForbidden
	}
	in.Role = strings.ToUpper(strings.TrimSpace(in.Role))
	in.DecisionRef = strings.TrimSpace(in.DecisionRef)
	in.FirstName, in.LastName = strings.TrimSpace(in.FirstName), strings.TrimSpace(in.LastName)
	if !siteRoles[in.Role] {
		return nil, fmt.Errorf("%w: rol MANAGER, BOARD_MEMBER, AUDITOR ya da STAFF olmalı", ErrInvalidRoleInput)
	}
	if rolesNeedingDecision[in.Role] && in.DecisionRef == "" {
		return nil, fmt.Errorf("%w: bu görev kat malikleri kurulu kararıyla verilir (KMK m.34/m.41); "+
			"karar tarihi ve sayısını decision_ref alanına yazın", ErrInvalidRoleInput)
	}
	// Başlangıç verilmezse veritabanının CURRENT_DATE'i kullanılır: uygulamanın
	// yerel saatiyle (UTC+3) hesaplanan "bugün", gece yarısından sonra veritabanı
	// gününden ileri düşüp yeni rolü bir gün geçersiz bırakıyordu.
	var from, to *time.Time
	if in.ValidFrom != "" {
		d, err := parseDay(in.ValidFrom)
		if err != nil {
			return nil, fmt.Errorf("%w: başlangıç tarihi YYYY-MM-DD olmalı", ErrInvalidRoleInput)
		}
		from = &d
	}
	if in.ValidTo != "" {
		d, err := parseDay(in.ValidTo)
		if err != nil {
			return nil, fmt.Errorf("%w: bitiş tarihi YYYY-MM-DD olmalı", ErrInvalidRoleInput)
		}
		if from != nil && d.Before(*from) {
			return nil, fmt.Errorf("%w: bitiş tarihi başlangıçtan önce olamaz", ErrInvalidRoleInput)
		}
		to = &d
	}

	unusable, err := GenerateCode()
	if err != nil {
		return nil, err
	}
	hash, err := bcrypt.GenerateFromPassword([]byte(unusable+unusable), bcrypt.DefaultCost)
	if err != nil {
		return nil, err
	}
	sr, created, userID, err := s.repo.Grant(ctx, propertyID, actorID, string(hash), in, from, to)
	if err != nil {
		return nil, err
	}
	out := &models.GrantRoleResult{Role: sr,
		Note: "Yeni yetki kişinin bir sonraki girişinde (ya da oturum yenilemesinde) geçerli olur."}
	if created && s.auth != nil {
		code, expires, purpose, err := s.auth.IssueActivation(ctx, userID, actorID, false)
		if err != nil {
			return nil, fmt.Errorf("görev verildi ama etkinleştirme kodu üretilemedi: %w", err)
		}
		out.Activation = activationOf(code, purpose, expires)
	}
	return out, nil
}

// End görevi sonlandırır ve kişinin açık oturumlarını kapatır: yetkisi biten
// birinin elindeki jeton 15 dakika daha yönetici yetkisi taşımasın.
func (s *RoleService) End(ctx context.Context, propertyID, id string, roles []string) (*models.SiteRole, error) {
	if !canManageRoles(roles) {
		return nil, ErrResidentForbidden
	}
	sr, userID, err := s.repo.End(ctx, propertyID, id)
	if err != nil {
		return nil, err
	}
	if s.revoker != nil {
		if err := s.revoker.RevokeAll(ctx, userID, "site_role_ended"); err != nil {
			return sr, fmt.Errorf("görev sonlandırıldı ama oturumlar kapatılamadı: %w", err)
		}
	}
	return sr, nil
}
