package service

import (
	"errors"
	"strings"
	"testing"
)

func TestCalculateTanimaUygun(t *testing.T) {
	// 10 yanıt: 6 tavsiye eden (9-10), 2 kararsız (7-8), 2 kötüleyen (0-6)
	// NPS = %60 − %20 = 40
	scores := []int{10, 10, 9, 9, 9, 10, 8, 7, 3, 0}
	r, err := Calculate(scores)
	if err != nil {
		t.Fatal(err)
	}
	if r.Promoters != 6 || r.Passives != 2 || r.Detractors != 2 {
		t.Fatalf("gruplama yanlış: %d/%d/%d", r.Promoters, r.Passives, r.Detractors)
	}
	if r.Score != 40 {
		t.Fatalf("NPS: %d (40 bekleniyordu)", r.Score)
	}
	if !r.Reliable {
		t.Fatal("10 yanıt güvenilmez sayıldı")
	}
}

func TestCalculateKararsizlarSkoraGirmezPaydadaSayilir(t *testing.T) {
	// 4 yanıtın tamamı kararsız → NPS 0 ama yanıt sayısı 4.
	r, err := Calculate([]int{7, 8, 7, 8})
	if err != nil {
		t.Fatal(err)
	}
	if r.Score != 0 {
		t.Fatalf("yalnızca kararsız varken NPS: %d (0 bekleniyordu)", r.Score)
	}
	if r.Responses != 4 {
		t.Fatalf("kararsızlar paydada sayılmadı: %d", r.Responses)
	}
}

func TestCalculateEnDusukVeEnYuksek(t *testing.T) {
	r, _ := Calculate([]int{10, 10, 10})
	if r.Score != 100 {
		t.Fatalf("hepsi tavsiye ederken: %d (100 bekleniyordu)", r.Score)
	}
	r, _ = Calculate([]int{0, 1, 2})
	if r.Score != -100 {
		t.Fatalf("hepsi kötülerken: %d (-100 bekleniyordu)", r.Score)
	}
}

func TestCalculateSinirDegerler(t *testing.T) {
	// 6 kötüleyen, 7 kararsız, 9 tavsiye eden sınırları tanımın parçasıdır.
	r, _ := Calculate([]int{6, 7, 9})
	if r.Detractors != 1 || r.Passives != 1 || r.Promoters != 1 {
		t.Fatalf("sınır değerler yanlış gruplandı: %d/%d/%d",
			r.Detractors, r.Passives, r.Promoters)
	}
}

func TestCalculateYanitYoksaSkorUretilmez(t *testing.T) {
	if _, err := Calculate(nil); !errors.Is(err, ErrNoResponses) {
		t.Fatalf("yanıtsız hesap üretildi: %v", err)
	}
	// Aralık dışı puanlar tek başına yanıt sayılmaz.
	if _, err := Calculate([]int{-1, 11, 99}); !errors.Is(err, ErrNoResponses) {
		t.Fatalf("aralık dışı puanlarla skor üretildi: %v", err)
	}
}

func TestCalculateKucukOrneklemGuvenilmezIsaretlenir(t *testing.T) {
	r, err := Calculate([]int{10, 0, 10})
	if err != nil {
		t.Fatal(err)
	}
	if r.Reliable {
		t.Fatal("3 yanıtlık örneklem güvenilir sayıldı")
	}
	if !strings.Contains(r.Note, "yönlendirici sayılmamalıdır") {
		t.Fatalf("küçük örneklem uyarısı yetersiz: %s", r.Note)
	}
}

func TestCalculateYorumUretilir(t *testing.T) {
	r, _ := Calculate([]int{10, 10, 10, 10, 10, 10, 10, 10, 10, 10})
	if r.Interpretation == "" {
		t.Fatal("skor yorumu üretilmedi")
	}
	if !strings.Contains(r.Interpretation, "Genel kabul") {
		t.Fatalf("yorumun kaynağı belirtilmemiş: %s", r.Interpretation)
	}
}
