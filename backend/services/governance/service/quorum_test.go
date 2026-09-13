package service

import "testing"

// KMK m.30 — birinci toplantıda "yarıdan fazla" aranır; TAM YARI YETMEZ.
// Bu ayrım kararın geçerliliğini belirler: 24 dairede 12 daire yeter sayı değildir.
func TestEvaluateQuorum_TamYariYetmez(t *testing.T) {
	// 24 bağımsız bölüm, 10000 arsa payı; 12 daire ve 5000 pay katıldı.
	r := EvaluateQuorum(1, 24, 10000, 12, 5000, 0.5, "KMK m.30")
	if r.Met {
		t.Errorf("tam yarı ile yeter sayı sağlandı sayıldı: %+v", r)
	}
	if r.ByCountMet || r.ByShareMet {
		t.Errorf("tam yarı her iki ölçüde de sağlanmış sayıldı")
	}
}

func TestEvaluateQuorum_YaridanFazlaYeter(t *testing.T) {
	r := EvaluateQuorum(1, 24, 10000, 13, 5001, 0.5, "KMK m.30")
	if !r.Met {
		t.Errorf("yarıdan fazla katılımda yeter sayı sağlanmadı: %s", r.Explanation)
	}
}

// Sayı yeterli ama arsa payı yetersizse nisap SAĞLANMAZ (m.30 iki ölçüyü birlikte arar).
func TestEvaluateQuorum_IkiOlcuBirlikteAranir(t *testing.T) {
	// 13 küçük daire katıldı (sayıca yeter) ama arsa payları toplamı yarıyı geçmiyor.
	r := EvaluateQuorum(1, 24, 10000, 13, 4000, 0.5, "KMK m.30")
	if r.Met {
		t.Errorf("arsa payı yetersizken nisap sağlandı sayıldı")
	}
	if !r.ByCountMet {
		t.Errorf("sayı ölçüsü yeterli olmalıydı")
	}
	if r.ByShareMet {
		t.Errorf("arsa payı ölçüsü yetersiz olmalıydı")
	}

	// Tersi: arsa payı yeter, sayı yetmez.
	r2 := EvaluateQuorum(1, 24, 10000, 10, 6000, 0.5, "KMK m.30")
	if r2.Met {
		t.Errorf("sayı yetersizken nisap sağlandı sayıldı")
	}
}

// İkinci toplantıda toplantı yeter sayısı aranmaz (m.30/3).
func TestEvaluateQuorum_IkinciToplanti(t *testing.T) {
	r := EvaluateQuorum(2, 24, 10000, 3, 1200, 0.5, "KMK m.30/3")
	if !r.Met {
		t.Errorf("ikinci toplantıda düşük katılımla nisap sağlanmadı: %s", r.Explanation)
	}
	// Hiç katılım yoksa toplantı yapılamaz.
	r0 := EvaluateQuorum(2, 24, 10000, 0, 0, 0.5, "KMK m.30/3")
	if r0.Met {
		t.Errorf("katılımsız ikinci toplantı geçerli sayıldı")
	}
}

func TestEvaluateQuorum_BosSite(t *testing.T) {
	r := EvaluateQuorum(1, 0, 0, 0, 0, 0.5, "KMK m.30")
	if r.Met {
		t.Errorf("birimi olmayan sitede nisap sağlandı sayıldı")
	}
}

// KMK m.19/2 — ortak yerlerde inşaat/onarım için 4/5 rıza. Tam 4/5 KABUL edilir.
func TestEvaluateMajority_DortteBes(t *testing.T) {
	// 20 daire, 10000 pay; 16 daire (4/5) ve 8000 pay kabul.
	r := EvaluateMajority("MAJORITY_CONSTRUCTION_CONSENT", 0.8, 1,
		20, 10000, 20, 10000, 16, 8000, "KMK m.19/2")
	if !r.Accepted {
		t.Errorf("tam 4/5 rıza reddedildi: %s", r.Explanation)
	}

	// 15 daire → 3/4, yetmez.
	r2 := EvaluateMajority("MAJORITY_CONSTRUCTION_CONSENT", 0.8, 1,
		20, 10000, 20, 10000, 15, 7500, "KMK m.19/2")
	if r2.Accepted {
		t.Errorf("4/5 altındaki rıza kabul edildi")
	}
}

// Özel nisaplarda payda TÜM kat malikleridir; toplantıya katılanlar değil.
func TestEvaluateMajority_OzelNisaptaPaydaTumMalikler(t *testing.T) {
	// 20 daireden yalnızca 16'sı katıldı ve hepsi kabul oyu verdi.
	// Yönetim planı değişikliği (4/5) için 16/20 = 4/5 → kabul.
	r := EvaluateMajority("MAJORITY_MANAGEMENT_PLAN_CHANGE", 0.8, 1,
		20, 10000, 16, 8000, 16, 8000, "KMK m.28")
	if !r.Accepted {
		t.Errorf("16/20 kabul oyu 4/5 nisabını sağlamalıydı: %s", r.Explanation)
	}

	// 12 katılımcının tamamı kabul etse bile 12/20 = %60 → 4/5 sağlanmaz.
	r2 := EvaluateMajority("MAJORITY_MANAGEMENT_PLAN_CHANGE", 0.8, 1,
		20, 10000, 12, 6000, 12, 6000, "KMK m.28")
	if r2.Accepted {
		t.Errorf("katılanların tamamı kabul etse de özel nisap sağlanmamalıydı")
	}
}

// KMK m.45 — oybirliği. Tek ret bile yeterlidir.
func TestEvaluateMajority_Oybirligi(t *testing.T) {
	r := EvaluateMajority("UNANIMITY_TRANSFER_ACTS", 1.0, 1,
		10, 5000, 10, 5000, 10, 5000, "KMK m.45")
	if !r.Accepted {
		t.Errorf("tam oybirliği reddedildi: %s", r.Explanation)
	}

	r2 := EvaluateMajority("UNANIMITY_TRANSFER_ACTS", 1.0, 1,
		10, 5000, 10, 5000, 9, 4500, "KMK m.45")
	if r2.Accepted {
		t.Errorf("9/10 oy ile oybirliği sağlandı sayıldı")
	}
}

// Olağan kararlar: ikinci toplantıda payda KATILANLAR olur (m.30/3).
func TestEvaluateMajority_OlaganKararIkinciToplanti(t *testing.T) {
	// 24 daireden 6'sı katıldı, 4'ü kabul → katılanların salt çoğunluğu sağlandı.
	r := EvaluateMajority("", 0, 2, 24, 10000, 6, 2500, 4, 1700, "")
	if !r.Accepted {
		t.Errorf("ikinci toplantıda katılanların çoğunluğu kabul edilmedi: %s", r.Explanation)
	}

	// Aynı oylar birinci toplantıda olsaydı payda tüm malikler olur ve yetmezdi.
	r2 := EvaluateMajority("", 0, 1, 24, 10000, 6, 2500, 4, 1700, "")
	if r2.Accepted {
		t.Errorf("birinci toplantıda 4/24 oy ile karar alındı sayıldı")
	}
}

// Olağan kararda da sayı ve arsa payı birlikte aranır.
func TestEvaluateMajority_SayiVeArsaPayiBirlikte(t *testing.T) {
	// 24 daireden 13'ü kabul (sayıca çoğunluk) ama arsa payı yarıyı geçmiyor.
	r := EvaluateMajority("", 0, 1, 24, 10000, 24, 10000, 13, 4000, "")
	if r.Accepted {
		t.Errorf("arsa payı yetersizken karar kabul edildi")
	}
}
