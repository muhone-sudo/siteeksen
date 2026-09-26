package middleware

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// UUIDParams, yoldaki kimlik parametrelerinin (`:id`, `:itemId`,
// `:objectionId` …) UUID biçiminde olduğunu doğrular; değilse 404 döner.
//
// NEDEN VAR (2026-09-26): biçimi bozuk kimlik veritabanına gidiyor ve
// PostgreSQL onu tür hatasıyla (22P02) reddediyordu. Servislerin çoğu bunu
// 500 olarak döndürüyordu: `/employees/stats` gibi var olmayan bir alt yol
// `:id = "stats"` olarak eşleşip "sunucu hatası" üretiyordu. Bu hem yanlış
// (kayıt yok, sunucu arızalı değil) hem de izleme sisteminde sahte alarm
// demektir. Denetim tek yerde yapılır; her depo fonksiyonuna ayrı ayrı
// eklenseydi biri mutlaka unutulurdu.
//
// Yalnızca adı `id` olan ya da `Id` ile biten parametreler denetlenir;
// `:key`, `:plate` gibi serbest metin parametreleri etkilenmez.
func UUIDParams() gin.HandlerFunc {
	return func(c *gin.Context) {
		for _, p := range c.Params {
			if p.Key != "id" && !strings.HasSuffix(p.Key, "Id") {
				continue
			}
			if _, err := uuid.Parse(p.Value); err != nil {
				c.AbortWithStatusJSON(http.StatusNotFound, gin.H{"error": "Kayıt bulunamadı"})
				return
			}
		}
		c.Next()
	}
}
