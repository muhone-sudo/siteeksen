// Package stub, henüz gerçek bir veri katmanına bağlanmamış HTTP uçları için
// tek tip ve DÜRÜST bir yanıt üretir.
//
// NEDEN VAR:
// 2026-09-09 denetiminde 25 servisten 22'sinin sabit (uydurma) JSON döndürdüğü,
// yazma isteklerine 200/201 dönüp veriyi hiçbir yere kaydetmediği tespit edildi.
// Bu davranış kullanıcıya yalan söyler: ödeme, tahakkuk, ziyaretçi kaydı gibi
// işlemler "başarılı" görünür ama yoktur.
//
// tasks/dogrulama-politikasi.md §3.5 uyarınca kalıcı olmayan bir uç 2xx dönemez.
// Bu paket o kuralı tek bir yerden uygular.
package stub

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// HeaderNotImplemented, istemcilerin (panel/mobil) bu durumu programatik olarak
// ayırt edebilmesi için eklenen yanıt başlığıdır.
const HeaderNotImplemented = "X-SiteEksen-Not-Implemented"

// Response, uygulanmamış uçların gövde sözleşmesidir.
type Response struct {
	Error   string `json:"error"`
	Module  string `json:"module"`
	Message string `json:"message"`
	Detail  string `json:"detail,omitempty"`
	Docs    string `json:"docs"`
}

const (
	defaultMessage = "Bu uç noktası henüz gerçek veri katmanına bağlanmamıştır. " +
		"İstek İŞLENMEDİ ve hiçbir veri kaydedilmedi."
	docsRef = "tasks/todo.md (FAZ 5) — modül gerçek veritabanına bağlanana kadar 501 döner"
)

// NotImplemented, 501 ile birlikte açıklayıcı bir gövde döndürür ve isteği sonlandırır.
func NotImplemented(c *gin.Context, module string) {
	notImplemented(c, module, "")
}

// NotImplementedDetail, modüle özel ek açıklama ile 501 döndürür.
func NotImplementedDetail(c *gin.Context, module, detail string) {
	notImplemented(c, module, detail)
}

func notImplemented(c *gin.Context, module, detail string) {
	c.Header(HeaderNotImplemented, "true")
	c.AbortWithStatusJSON(http.StatusNotImplemented, Response{
		Error:   "not_implemented",
		Module:  module,
		Message: defaultMessage,
		Detail:  detail,
		Docs:    docsRef,
	})
}

// Handler, rota kaydında doğrudan kullanılabilecek bir gin.HandlerFunc üretir.
func Handler(module string) gin.HandlerFunc {
	return func(c *gin.Context) { NotImplemented(c, module) }
}

// Health, tamamen stub olan bir servisin sağlık ucudur.
// status alanı bilerek "healthy" DEĞİLDİR: servis ayakta olabilir ama işlevsel değildir.
func Health(module string) gin.HandlerFunc {
	return func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":     "not_implemented",
			"service":    module,
			"persistent": false,
			"message":    "Servis ayakta; ancak hiçbir uç gerçek veriye bağlı değil.",
		})
	}
}
