package audit

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/jackc/pgx/v5/pgxpool"
)

// Entry bir denetim izi kaydını tanımlar.
//
// Not (2026-09-09): Önceki sürüm 9 konumsal parametre alıyordu ve yazdığı kolon adları
// şemayla uyuşmuyordu (user_ip/resource_type/resource_id ⟷ ip_address/entity_type/entity_id),
// bu yüzden INSERT her çağrıda hata veriyor ve hata çağıran tarafta yutulduğu için
// `audit_logs` tablosu kalıcı olarak boş kalıyordu. Bkz. migration 011.
type Entry struct {
	// UserID işlemi yapan kullanıcı (boş olabilir: kimliksiz istek / sistem işlemi → NULL yazılır)
	UserID string
	// PropertyID işlemin kapsamı olan site/taşınmaz (boş olabilir → NULL)
	PropertyID string
	// IPAddress isteğin geldiği adres (boş olabilir → NULL)
	IPAddress string
	// UserAgent istemci bilgisi
	UserAgent string
	// Action VIEW / CREATE / UPDATE / DELETE / DENIED
	Action string
	// EntityType erişilen kaynak türü (örn. "user", "resident", "finance", "request")
	EntityType string
	// EntityID erişilen kaynağın kimliği (boş olabilir: liste/oluşturma istekleri → NULL)
	EntityID string
	// RequestID aynı istekten doğan kayıtları ilişkilendirmek için korelasyon kimliği
	RequestID string
	// StatusCode HTTP yanıt kodu — yetkisiz denemeleri (401/403) başarılı erişimden ayırır
	StatusCode int
	// OldValues / NewValues değişiklik öncesi ve sonrası değerler (JSONB olarak saklanır)
	OldValues interface{}
	NewValues interface{}
}

// Log verilen denetim kaydını `audit_logs` tablosuna ekler.
//
// Kolon adları migration 003 + 011'deki şema ile birebir uyumludur.
// Boş string olarak gelen kimlik/adres alanları NULL yazılır.
func Log(ctx context.Context, pool *pgxpool.Pool, e Entry) error {
	if pool == nil {
		return nil
	}

	oldJSON, err := marshalOrNil(e.OldValues)
	if err != nil {
		return fmt.Errorf("audit: old_values serileştirilemedi: %w", err)
	}
	newJSON, err := marshalOrNil(e.NewValues)
	if err != nil {
		return fmt.Errorf("audit: new_values serileştirilemedi: %w", err)
	}

	const query = `
		INSERT INTO audit_logs (
			user_id, property_id, ip_address, user_agent,
			action, entity_type, entity_id,
			request_id, status_code, old_values, new_values
		) VALUES (
			NULLIF($1, '')::uuid, NULLIF($2, '')::uuid, NULLIF($3, '')::inet, NULLIF($4, ''),
			$5, $6, NULLIF($7, '')::uuid,
			NULLIF($8, ''), NULLIF($9, 0), $10, $11
		)
	`

	if _, err := pool.Exec(ctx, query,
		e.UserID, e.PropertyID, e.IPAddress, e.UserAgent,
		e.Action, e.EntityType, e.EntityID,
		e.RequestID, e.StatusCode, oldJSON, newJSON,
	); err != nil {
		return fmt.Errorf("audit: kayıt eklenemedi (action=%s entity=%s): %w", e.Action, e.EntityType, err)
	}
	return nil
}

// LogAction geriye dönük uyumluluk için tutulan sarmalayıcıdır.
//
// Yeni kod doğrudan Log(ctx, pool, Entry{...}) kullanmalıdır; bu imza yalnızca
// mevcut çağrı noktalarının kırılmaması için korunmuştur.
func LogAction(
	ctx context.Context,
	pool *pgxpool.Pool,
	userID, ipAddress, userAgent, action, entityType, entityID string,
	oldValues, newValues interface{},
) error {
	return Log(ctx, pool, Entry{
		UserID:     userID,
		IPAddress:  ipAddress,
		UserAgent:  userAgent,
		Action:     action,
		EntityType: entityType,
		EntityID:   entityID,
		OldValues:  oldValues,
		NewValues:  newValues,
	})
}

func marshalOrNil(v interface{}) ([]byte, error) {
	if v == nil {
		return nil, nil
	}
	return json.Marshal(v)
}
