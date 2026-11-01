package iyzico

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestPrice(t *testing.T) {
	cases := map[int64]string{64000: "640.0", 25050: "250.5", 12345: "123.45", 1: "0.01", 100: "1.0"}
	for k, want := range cases {
		if got := Price(k); got != want {
			t.Errorf("Price(%d) = %q; beklenen %q", k, got, want)
		}
	}
	for in, want := range map[string]int64{"640.0": 64000, "250.5": 25050, "123.45": 12345, "640": 64000, "1.230": 123} {
		if got, err := ParsePriceKurus(json.Number(in)); err != nil || got != want {
			t.Errorf("ParsePriceKurus(%q) = %d, %v; beklenen %d", in, got, err, want)
		}
	}
	if _, err := ParsePriceKurus(json.Number("1.234")); err == nil {
		t.Error("kuruştan hassas tutar reddedilmeliydi")
	}
}

// İmza, sunucu tarafında aynı girdilerden yeniden üretilebilmeli (IYZWSv2).
func TestInitializeSignsRequestAndParses(t *testing.T) {
	var gotAuth, gotRnd, gotPath string
	var gotBody []byte
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		gotAuth, gotRnd, gotPath = r.Header.Get("Authorization"), r.Header.Get("x-iyzi-rnd"), r.URL.Path
		gotBody, _ = io.ReadAll(r.Body)
		_, _ = w.Write([]byte(`{"status":"success","token":"tok-1","paymentPageUrl":"https://pay.example/tok-1","tokenExpireTime":1800}`))
	}))
	defer srv.Close()
	c := &Client{APIKey: "ak", SecretKey: "sk", BaseURL: srv.URL, CallbackURL: "https://site.example/cb", HTTP: srv.Client()}
	out, err := c.Initialize(context.Background(), InitializeRequest{ConversationID: "p1", Price: "640.0", PaidPrice: "640.0", BasketID: "p1",
		BasketItems: []BasketItem{{ID: "a1", Name: "Aidat", Category1: "Aidat", ItemType: "VIRTUAL", Price: "640.0"}}})
	if err != nil || out.Token != "tok-1" || out.PaymentPageURL == "" {
		t.Fatalf("initialize: %+v %v", out, err)
	}
	if gotPath != initializePath {
		t.Errorf("yol: %s", gotPath)
	}
	if want := Authorization("ak", "sk", gotRnd, initializePath, gotBody); gotAuth != want || gotRnd == "" {
		t.Errorf("imza uyuşmuyor: %s / %s", gotAuth, want)
	}
	var sent map[string]any
	_ = json.Unmarshal(gotBody, &sent)
	if sent["locale"] != "tr" || sent["currency"] != "TRY" || sent["callbackUrl"] != "https://site.example/cb" {
		t.Errorf("gövde: %v", sent)
	}
}

func TestRetrieveFailureIsAPIError(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		_, _ = w.Write([]byte(`{"status":"failure","errorCode":"5139","errorMessage":"Geçersiz token"}`))
	}))
	defer srv.Close()
	c := &Client{APIKey: "ak", SecretKey: "sk", BaseURL: srv.URL, CallbackURL: "https://x/cb", HTTP: srv.Client()}
	_, err := c.Retrieve(context.Background(), "t", "p")
	if ae, ok := err.(*APIError); !ok || ae.Code != "5139" {
		t.Fatalf("APIError beklenirdi: %v", err)
	}
}

// İade: v2 yolu, kuruştan tutar metni, imza; sağlayıcının farklı tutar döndürmesi hatadır.
func TestRefundSignsAndChecksAmount(t *testing.T) {
	var gotAuth, gotRnd, gotPath string
	var gotBody []byte
	reply := `{"status":"success","paymentId":"P1","price":"125.5","refundHostReference":"R1"}`
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		gotAuth, gotRnd, gotPath = r.Header.Get("Authorization"), r.Header.Get("x-iyzi-rnd"), r.URL.Path
		gotBody, _ = io.ReadAll(r.Body)
		_, _ = w.Write([]byte(reply))
	}))
	defer srv.Close()
	c := &Client{APIKey: "ak", SecretKey: "sk", BaseURL: srv.URL, CallbackURL: "https://x/cb", HTTP: srv.Client()}
	out, err := c.Refund(context.Background(), "P1", 12550, "r1", "127.0.0.1")
	if err != nil || out.RefundHostReference != "R1" {
		t.Fatalf("iade: %+v %v", out, err)
	}
	if gotPath != refundPath {
		t.Errorf("yol: %s", gotPath)
	}
	if want := Authorization("ak", "sk", gotRnd, refundPath, gotBody); gotAuth != want {
		t.Errorf("imza uyuşmuyor")
	}
	var sent map[string]any
	_ = json.Unmarshal(gotBody, &sent)
	if sent["paymentId"] != "P1" || sent["price"] != "125.5" || sent["currency"] != "TRY" {
		t.Errorf("gövde: %v", sent)
	}
	reply = `{"status":"success","paymentId":"P1","price":"100.0"}`
	if _, err := c.Refund(context.Background(), "P1", 12550, "r1", ""); err == nil {
		t.Error("farklı iade tutarı hata olmalıydı")
	}
	reply = `{"status":"failure","errorCode":"5089","errorMessage":"İade süresi geçti"}`
	if _, err := c.Refund(context.Background(), "P1", 12550, "r1", ""); err == nil {
		t.Error("failure yanıtı hata olmalıydı")
	}
}

func TestClassify(t *testing.T) {
	if k, m := Classify("10051", ""); k != "CARD" || m != "Kartınızın limiti yetersiz." {
		t.Errorf("10051: %s %s", k, m)
	}
	if k, _ := Classify("10219", ""); k != "SYSTEM" {
		t.Errorf("zaman aşımı sistem hatası olmalı: %s", k)
	}
	if k, m := Classify("99999", "Bilinmeyen hata"); k != "SYSTEM" || m != "Bilinmeyen hata" {
		t.Errorf("bilinmeyen: %s %s", k, m)
	}
}

func TestFromEnvPartial(t *testing.T) {
	t.Setenv("IYZICO_API_KEY", "x")
	t.Setenv("IYZICO_SECRET_KEY", "")
	t.Setenv("IYZICO_BASE_URL", "")
	t.Setenv("IYZICO_CALLBACK_URL", "")
	if _, err := FromEnv(); err == nil {
		t.Error("yarım yapılandırma reddedilmeliydi")
	}
	t.Setenv("IYZICO_API_KEY", "")
	if c, err := FromEnv(); c != nil || err != nil {
		t.Errorf("yapılandırma yokken nil, nil beklenirdi: %v %v", c, err)
	}
}
