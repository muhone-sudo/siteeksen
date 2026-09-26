package middleware

import (
	"errors"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/siteeksen/backend/pkg/dbscope"
)

// DBErrorResponse, İSTEMCİDEN kaynaklanan bir veritabanı hatasını doğru HTTP
// yanıtına çevirir ve true döner. Hata istemci kaynaklı değilse hiçbir şey
// yazmaz ve false döner; çağıran o zaman 500 yazar.
//
// NEDEN VAR (2026-09-26): servislerin hata eşleyicileri tanımadıkları her
// hatayı 500 yapıyordu. Oysa gövdede UUID biçiminde olmayan bir kimlik,
// veritabanı CHECK kısıtına uymayan bir durum değeri ya da sütun uzunluğunu
// aşan bir metin SUNUCU arızası değildir — istemcinin düzeltebileceği bir
// girdidir. 500 dönmek istemciye "tekrar dene" der (boşuna), izleme
// sisteminde sahte alarm üretir ve gerçek arızaları gürültüde boğar.
//
// Veritabanının iç ayrıntısı (kısıt adı, sütun adı, SQL) istemciye
// SIZDIRILMAZ; yalnızca genel ve anlaşılır bir mesaj döner.
func DBErrorResponse(c *gin.Context, err error) bool {
	if errors.Is(err, dbscope.ErrNoProperty) {
		c.JSON(http.StatusForbidden, gin.H{
			"error": "Aktif site seçilmemiş; işlem yapılamaz",
			"note":  "Oturumunuzda site bilgisi yok. Site seçip yeniden deneyin.",
		})
		return true
	}
	var pg *pgconn.PgError
	if !errors.As(err, &pg) {
		return false
	}
	switch pg.Code {
	case "22P02": // invalid_text_representation — örn. UUID olmayan kimlik
		c.JSON(http.StatusBadRequest, gin.H{"error": "Bir alanın biçimi geçersiz (örneğin kimlik UUID değil)"})
	case "22001": // string_data_right_truncation
		c.JSON(http.StatusBadRequest, gin.H{"error": "Bir alan izin verilen uzunluğu aşıyor"})
	case "22007", "22008": // tarih/saat biçimi ya da aralığı
		c.JSON(http.StatusBadRequest, gin.H{"error": "Tarih ya da saat değeri geçersiz"})
	case "22003": // numeric_value_out_of_range
		c.JSON(http.StatusBadRequest, gin.H{"error": "Sayısal değer izin verilen aralığın dışında"})
	case "23514": // check_violation — izin verilmeyen durum/tür değeri
		c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Bir alanın değeri izin verilen değerlerden biri değil"})
	case "23502": // not_null_violation
		c.JSON(http.StatusBadRequest, gin.H{"error": "Zorunlu bir alan boş bırakılmış"})
	case "23503": // foreign_key_violation — var olmayan bir kayda başvuru
		c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Başvurulan kayıt bulunamadı"})
	case "23505": // unique_violation
		c.JSON(http.StatusConflict, gin.H{"error": "Bu kayıt zaten mevcut"})
	default:
		return false
	}
	return true
}
