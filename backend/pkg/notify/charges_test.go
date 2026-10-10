package notify

import (
	"strings"
	"testing"
	"time"
)

func TestChargeTextDonemTutarVade(t *testing.T) {
	today := time.Date(2026, 3, 1, 10, 0, 0, 0, time.Local)
	c := chargeRow{unit: "A-5", kind: "REGULAR", year: 2026, month: 3, kurus: 123456,
		due: time.Date(2026, 3, 15, 0, 0, 0, 0, time.Local)}
	subject, body := chargeText(c, today)
	for _, want := range []string{"A-5", "2026-03 dönemi aidatı", "15.03.2026"} {
		if !strings.Contains(body, want) {
			t.Fatalf("gövdede %q yok: %s", want, body)
		}
	}
	if !strings.Contains(subject, "Yeni borç") {
		t.Fatalf("başlık: %s", subject)
	}
	if strings.Contains(body, "bugünden önceki") {
		t.Fatalf("vadesi gelecekte olan borçta geçmiş tarih uyarısı olmamalı: %s", body)
	}
}

func TestChargeTextGecmisVadeVeDevir(t *testing.T) {
	today := time.Date(2026, 3, 20, 10, 0, 0, 0, time.Local)
	c := chargeRow{unit: "B-2", kind: "OPENING", description: "2025 yakıt farkı", year: 2026, month: 3, kurus: 5000,
		due: time.Date(2026, 3, 15, 0, 0, 0, 0, time.Local)}
	_, body := chargeText(c, today)
	for _, want := range []string{"Devir bakiyesi", "2025 yakıt farkı", "bugünden önceki"} {
		if !strings.Contains(body, want) {
			t.Fatalf("gövdede %q yok: %s", want, body)
		}
	}
}

func TestMergeResultAliciIkiKanaldaTekSayilir(t *testing.T) {
	total := &BroadcastResult{}
	mergeResult(total, &BroadcastResult{Recipients: 2, Sent: 2}, true)
	mergeResult(total, &BroadcastResult{Recipients: 2, Pending: 2}, false)
	if total.Recipients != 2 || total.Sent != 2 || total.Pending != 2 {
		t.Fatalf("toplam yanlış: %+v", total)
	}
}

func TestNotifyChargesNilNotifier(t *testing.T) {
	res := NotifyCharges(t.Context(), nil, nil, "p", "u", []string{"x"})
	if res == nil || !strings.Contains(res.Note, "kurulu değil") {
		t.Fatalf("nil notifier açıkça bildirilmeli: %+v", res)
	}
}
