package main

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// meta: pazaryeri ayarları, etkin kategoriler ve etkin paketler.
func (a *App) meta(c *gin.Context) {
	m, err := a.store.Meta(c.Request.Context())
	if err != nil {
		fail(c, err, "pazaryeri bilgileri")
		return
	}
	c.JSON(http.StatusOK, m)
}

// supplierMe: tedarikçinin hesabı; hesap henüz açılmadıysa 404 ve ne yapılacağı.
func (a *App) supplierMe(c *gin.Context) {
	acc, err := a.store.AccountOfUser(c.Request.Context(), c.GetString("user_id"))
	if err != nil {
		fail(c, err, "tedarikçi hesabı")
		return
	}
	if acc == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Tedarikçi hesabınız henüz oluşturulmadı", "code": "NO_ACCOUNT"})
		return
	}
	c.JSON(http.StatusOK, acc)
}
