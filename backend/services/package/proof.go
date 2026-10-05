package main

// Kargo teslim kanıtı: imza ve paket fotoğrafı (TEST_RAPORU 2.3, migration 052).
//
// Dosyalar pkg/storage'a (belge arşiviyle aynı depo, anahtar öneki packages/) yazılır;
// kayıtta depo anahtarı ve SHA-256 özeti tutulur. Depo yapılandırılmamışsa servis yine
// açılır ama kanıt yüklenmek istendiğinde 503 döner — "kaydedildi" denip dosya
// sessizce atılmaz.

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"log"
	"mime/multipart"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/dbscope"
	"github.com/siteeksen/backend/pkg/storage"
	"github.com/siteeksen/backend/services/package/repository"
)

// proofMaxBytes: imza/fotoğraf başına üst sınır.
const proofMaxBytes = 5 << 20

var proofTypes = map[string]string{"image/png": "png", "image/jpeg": "jpg", "image/webp": "webp"}

// proofFile, yüklenmeye hazır kanıt dosyasıdır.
type proofFile struct {
	data        []byte
	contentType string
	ext         string
	sha         string
}

// readProof, multipart alanını okur ve içeriği (uzantıya değil, baytlara bakarak) doğrular.
func readProof(fh *multipart.FileHeader) (*proofFile, error) {
	if fh == nil {
		return nil, nil
	}
	if fh.Size > proofMaxBytes {
		return nil, fmt.Errorf("dosya %d MB sınırını aşıyor", proofMaxBytes>>20)
	}
	f, err := fh.Open()
	if err != nil {
		return nil, err
	}
	defer f.Close()
	data, err := io.ReadAll(io.LimitReader(f, proofMaxBytes+1))
	if err != nil {
		return nil, err
	}
	if len(data) == 0 || len(data) > proofMaxBytes {
		return nil, fmt.Errorf("dosya boş ya da %d MB sınırını aşıyor", proofMaxBytes>>20)
	}
	ct := http.DetectContentType(data)
	ext, ok := proofTypes[ct]
	if !ok {
		return nil, fmt.Errorf("yalnızca PNG, JPEG ya da WEBP görsel kabul edilir (gelen: %s)", ct)
	}
	sum := sha256.Sum256(data)
	return &proofFile{data: data, contentType: ct, ext: ext, sha: hex.EncodeToString(sum[:])}, nil
}

// deliverWithProof: multipart teslim — delivered_to_name + isteğe bağlı signature/photo dosyaları.
func deliverWithProof(c *gin.Context, repo *repository.Repository, pool *pgxpool.Pool, store storage.Store) {
	if err := c.Request.ParseMultipartForm(2*proofMaxBytes + 1<<20); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Form okunamadı ya da dosyalar çok büyük"})
		return
	}
	name := strings.TrimSpace(c.Request.FormValue("delivered_to_name"))
	if name == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Teslim alan kişinin adı (delivered_to_name) zorunludur"})
		return
	}
	var sig, photo *proofFile
	var err error
	if fhs := c.Request.MultipartForm.File["signature"]; len(fhs) > 0 {
		if sig, err = readProof(fhs[0]); err != nil {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "İmza: " + err.Error()})
			return
		}
	}
	if fhs := c.Request.MultipartForm.File["photo"]; len(fhs) > 0 {
		if photo, err = readProof(fhs[0]); err != nil {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Fotoğraf: " + err.Error()})
			return
		}
	}
	if (sig != nil || photo != nil) && store == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Dosya deposu yapılandırılmamış; imza/fotoğraf kaydedilemez. Teslim KAYDEDİLMEDİ.",
			"note": "STORAGE_BACKEND (local|s3) ayarlanınca kanıt saklanır; şimdilik dosyasız teslim girebilirsiniz."})
		return
	}
	propertyID := c.GetString("property_id")
	ctx := c.Request.Context()
	// Önce durum denetimi: teslim edilemeyecek kayda dosya yüklenmez.
	if _, err := repo.Get(ctx, propertyID, c.Param("id"), ""); err != nil {
		fail(c, err, "kargo okuma")
		return
	}
	put := func(kind string, p *proofFile) (*string, *string, error) {
		if p == nil {
			return nil, nil, nil
		}
		key := fmt.Sprintf("packages/%s/%s/%s-%s.%s", propertyID, c.Param("id"), kind, p.sha[:12], p.ext)
		if _, err := store.Put(ctx, key, p.contentType, bytes.NewReader(p.data)); err != nil {
			return nil, nil, err
		}
		return &key, &p.sha, nil
	}
	sigKey, sigSHA, err := put("signature", sig)
	if err != nil {
		proofStoreFail(c, err)
		return
	}
	photoKey, photoSHA, err := put("photo", photo)
	if err != nil {
		cleanup(ctx, store, sigKey)
		proofStoreFail(c, err)
		return
	}
	tag, err := dbscope.For(pool, propertyID).Exec(ctx, `
		UPDATE packages SET status = 'DELIVERED', delivered_at = now(), delivered_by = NULLIF($3,'')::uuid,
		       delivered_to_name = $4, delivery_signature_url = $5, delivery_signature_sha256 = $6,
		       delivery_photo_url = $7, delivery_photo_sha256 = $8
		WHERE id = $1 AND property_id = $2 AND status IN ('RECEIVED','NOTIFIED')`,
		c.Param("id"), propertyID, c.GetString("user_id"), name, sigKey, sigSHA, photoKey, photoSHA)
	if err != nil || tag.RowsAffected() == 0 {
		// Teslim yazılamadıysa yüklenen dosya sahipsiz kalmasın.
		cleanup(ctx, store, sigKey)
		cleanup(ctx, store, photoKey)
		if err != nil {
			fail(c, err, "teslim")
			return
		}
		c.JSON(http.StatusConflict, gin.H{"error": "Kargo teslim edilebilir durumda değil"})
		return
	}
	saved := []string{}
	if sigKey != nil {
		saved = append(saved, "imza")
	}
	if photoKey != nil {
		saved = append(saved, "fotoğraf")
	}
	note := "Teslim kaydedildi. İmza/fotoğraf yüklenmedi."
	if len(saved) > 0 {
		note = "Teslim kaydedildi; " + strings.Join(saved, " ve ") + " SHA-256 özetiyle saklandı."
	}
	c.JSON(http.StatusOK, gin.H{"status": "DELIVERED", "signature_sha256": sigSHA, "photo_sha256": photoSHA, "note": note})
}

func cleanup(ctx context.Context, store storage.Store, key *string) {
	if key != nil && store != nil {
		if err := store.Delete(ctx, *key); err != nil {
			log.Printf("[package] sahipsiz kanıt dosyası silinemedi (%s): %v", *key, err)
		}
	}
}

func proofStoreFail(c *gin.Context, err error) {
	log.Printf("[package] kanıt dosyası yazılamadı: %v", err)
	c.JSON(http.StatusBadGateway, gin.H{"error": "İmza/fotoğraf depoya yazılamadı; teslim KAYDEDİLMEDİ"})
}

// getProof: GET /packages/:id/proof/:kind (signature|photo) — yönetim/görevli ya da paketin dairesi.
// Dosya teslimde kaydedilen özetle karşılaştırılır; tutmazsa verilmez.
func getProof(repo *repository.Repository, pool *pgxpool.Pool, store storage.Store) gin.HandlerFunc {
	return func(c *gin.Context) {
		kind := c.Param("kind")
		if kind != "signature" && kind != "photo" {
			c.JSON(http.StatusNotFound, gin.H{"error": "Kayıt bulunamadı"})
			return
		}
		if store == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Dosya deposu yapılandırılmamış"})
			return
		}
		propertyID := c.GetString("property_id")
		scope := ""
		if !hasOpsScope(c) {
			unitID, err := repo.ResidentUnit(c.Request.Context(), propertyID, c.GetString("user_id"))
			if err != nil {
				fail(c, err, "bağımsız bölüm çözümleme")
				return
			}
			scope = unitID
		}
		if _, err := repo.Get(c.Request.Context(), propertyID, c.Param("id"), scope); err != nil {
			fail(c, err, "kargo okuma")
			return
		}
		var key, sha *string
		col := map[string]string{"signature": "delivery_signature", "photo": "delivery_photo"}[kind]
		err := dbscope.For(pool, propertyID).QueryRow(c.Request.Context(),
			`SELECT `+col+`_url, `+col+`_sha256 FROM packages WHERE id = $1 AND property_id = $2`,
			c.Param("id"), propertyID).Scan(&key, &sha)
		if errors.Is(err, pgx.ErrNoRows) || (err == nil && (key == nil || !strings.HasPrefix(*key, "packages/"))) {
			c.JSON(http.StatusNotFound, gin.H{"error": "Bu teslim için kanıt dosyası yok"})
			return
		}
		if err != nil {
			fail(c, err, "kanıt okuma")
			return
		}
		rc, obj, err := store.Get(c.Request.Context(), *key)
		if err != nil {
			log.Printf("[package] kanıt dosyası okunamadı: %v", err)
			c.JSON(http.StatusNotFound, gin.H{"error": "Kanıt dosyası depoda bulunamadı"})
			return
		}
		defer rc.Close()
		data, err := io.ReadAll(io.LimitReader(rc, proofMaxBytes+1))
		if err != nil {
			fail(c, err, "kanıt okuma")
			return
		}
		sum := sha256.Sum256(data)
		if sha == nil || hex.EncodeToString(sum[:]) != *sha {
			log.Printf("[package] kanıt dosyası özeti tutmuyor: %s", *key)
			c.JSON(http.StatusConflict, gin.H{"error": "Kanıt dosyası teslimde kaydedilen özetle uyuşmuyor; dosya değiştirilmiş olabilir"})
			return
		}
		ct := "application/octet-stream"
		if obj != nil && obj.ContentType != "" {
			ct = obj.ContentType
		}
		c.Header("X-Content-SHA256", *sha)
		c.Header("Cache-Control", "private, no-store")
		c.Data(http.StatusOK, ct, data)
	}
}

// runDeletionQueue, KVKK imhasıyla kuyruğa bırakılan kanıt dosyalarını siler (052).
// Kuyruk site kapsamlıdır (RLS); işi olan siteler storage_deletion_property_ids() ile bulunur.
func runDeletionQueue(ctx context.Context, pool *pgxpool.Pool, store storage.Store) (int, error) {
	if store == nil {
		return 0, nil
	}
	rows, err := pool.Query(ctx, `SELECT id::text FROM storage_deletion_property_ids() AS id`)
	if err != nil {
		return 0, err
	}
	var props []string
	for rows.Next() {
		var id string
		if err := rows.Scan(&id); err != nil {
			rows.Close()
			return 0, err
		}
		props = append(props, id)
	}
	rows.Close()
	deleted := 0
	for _, p := range props {
		sc := dbscope.For(pool, p)
		qrows, err := sc.Query(ctx, `SELECT id::text, storage_key FROM storage_deletion_queue WHERE property_id = $1 ORDER BY created_at LIMIT 500`, p)
		if err != nil {
			return deleted, err
		}
		type item struct{ id, key string }
		var items []item
		for qrows.Next() {
			var it item
			if err := qrows.Scan(&it.id, &it.key); err != nil {
				qrows.Close()
				return deleted, err
			}
			items = append(items, it)
		}
		qrows.Close()
		for _, it := range items {
			if err := store.Delete(ctx, it.key); err != nil && !errors.Is(err, storage.ErrNotFound) {
				log.Printf("[package] imha kuyruğu: %s silinemedi: %v", it.key, err)
				continue // kuyrukta kalır, sonraki turda yeniden denenir
			}
			if _, err := sc.Exec(ctx, `DELETE FROM storage_deletion_queue WHERE id = $1`, it.id); err != nil {
				return deleted, err
			}
			deleted++
		}
	}
	return deleted, nil
}

// startDeletionWorker, kuyruğu açılışta ve her 15 dakikada bir (PACKAGE_PURGE_INTERVAL) işler.
func startDeletionWorker(pool *pgxpool.Pool, store storage.Store) {
	if store == nil {
		return
	}
	interval := 15 * time.Minute
	if v, err := time.ParseDuration(os.Getenv("PACKAGE_PURGE_INTERVAL")); err == nil && v >= time.Second {
		interval = v
	}
	go func() {
		for {
			if n, err := runDeletionQueue(context.Background(), pool, store); err != nil {
				log.Printf("[package] imha kuyruğu: %v", err)
			} else if n > 0 {
				log.Printf("[package] imha kuyruğu: %d kanıt dosyası silindi", n)
			}
			time.Sleep(interval)
		}
	}()
}
