package service

import (
	"fmt"

	"github.com/siteeksen/backend/services/governance/models"
)

// EvaluateQuorum, toplantı yeter sayısını hesaplar.
//
// KMK m.30:
//   - Birinci toplantı: kat maliklerinin SAYI ve ARSA PAYI bakımından YARIDAN FAZLASI
//     ile toplanır. "Yarıdan fazla" tam yarıyı KAPSAMAZ — 24 dairelik bir sitede 12
//     daire yetmez, 13 daire gerekir. Bu ayrım kararın geçerliliğini belirlediği için
//     `>` kullanılır, `>=` değil.
//   - İkinci toplantı: yeter sayı aranmaz; karar katılanların salt çoğunluğu ile alınır.
//
// requiredRatio, `legal_parameters` tablosundan gelir (GA_QUORUM_FIRST / GA_QUORUM_SECOND);
// koda gömülmez.
func EvaluateQuorum(
	callNumber int,
	totalUnits int, totalShare float64,
	attendedUnits int, attendedShare float64,
	requiredRatio float64,
	legalBasis string,
) models.QuorumResult {
	res := models.QuorumResult{
		TotalUnits:         totalUnits,
		TotalShareRatio:    totalShare,
		AttendedUnits:      attendedUnits,
		AttendedShareRatio: attendedShare,
		RequiredRatio:      requiredRatio,
		CallNumber:         callNumber,
		LegalBasis:         legalBasis,
	}

	// İkinci toplantıda toplantı yeter sayısı aranmaz (m.30/3).
	if callNumber >= 2 {
		res.ByCountMet = attendedUnits > 0
		res.ByShareMet = attendedUnits > 0
		res.Met = attendedUnits > 0
		if res.Met {
			res.Explanation = fmt.Sprintf(
				"İkinci toplantıda yeter sayı aranmaz; %d bağımsız bölüm katıldı, "+
					"karar katılanların salt çoğunluğu ile alınır.", attendedUnits)
		} else {
			res.Explanation = "İkinci toplantıda da hiç katılım yok; toplantı yapılamaz."
		}
		return res
	}

	if totalUnits <= 0 || totalShare <= 0 {
		res.Explanation = "Sitede tanımlı bağımsız bölüm ya da arsa payı bulunamadı; nisap hesaplanamaz."
		return res
	}

	// "Yarıdan fazla" → kesin büyüklük karşılaştırması.
	res.ByCountMet = float64(attendedUnits) > requiredRatio*float64(totalUnits)
	res.ByShareMet = attendedShare > requiredRatio*totalShare
	res.Met = res.ByCountMet && res.ByShareMet

	switch {
	case res.Met:
		res.Explanation = fmt.Sprintf(
			"Yeter sayı sağlandı: %d/%d bağımsız bölüm ve %.2f/%.2f arsa payı katıldı "+
				"(her iki ölçüde de yarıdan fazla).",
			attendedUnits, totalUnits, attendedShare, totalShare)
	case !res.ByCountMet && !res.ByShareMet:
		res.Explanation = fmt.Sprintf(
			"Yeter sayı SAĞLANMADI: ne sayı (%d/%d) ne arsa payı (%.2f/%.2f) yarıdan fazla. "+
				"İkinci toplantı yapılabilir.",
			attendedUnits, totalUnits, attendedShare, totalShare)
	case !res.ByCountMet:
		res.Explanation = fmt.Sprintf(
			"Yeter sayı SAĞLANMADI: arsa payı yeterli (%.2f/%.2f) ancak bağımsız bölüm sayısı "+
				"yarıdan fazla değil (%d/%d). KMK m.30 her iki ölçüyü de arar.",
			attendedShare, totalShare, attendedUnits, totalUnits)
	default:
		res.Explanation = fmt.Sprintf(
			"Yeter sayı SAĞLANMADI: bağımsız bölüm sayısı yeterli (%d/%d) ancak arsa payı "+
				"yarıdan fazla değil (%.2f/%.2f). KMK m.30 her iki ölçüyü de arar.",
			attendedUnits, totalUnits, attendedShare, totalShare)
	}
	return res
}

// EvaluateMajority, bir gündem maddesinin kabul edilip edilmediğini belirler.
//
// Nisap türleri ve dayanakları (oranlar legal_parameters'tan gelir):
//   - MAJORITY_INNOVATION (m.42): sayı VE arsa payı çoğunluğu → TÜM kat maliklerine oranla
//   - MAJORITY_CONSTRUCTION_CONSENT (m.19/2): 4/5 yazılı rıza → TÜM kat maliklerine oranla
//   - MAJORITY_MANAGEMENT_PLAN_CHANGE (m.28): 4/5 → TÜM kat maliklerine oranla
//   - UNANIMITY_TRANSFER_ACTS (m.45): oybirliği → TÜM kat malikleri
//   - Kod verilmezse: olağan karar. Birinci toplantıda tüm maliklerin salt çoğunluğu,
//     ikinci toplantıda KATILANLARIN salt çoğunluğu (m.30/3).
//
// base: karşılaştırmanın paydası. Özel nisaplarda daima TÜM kat malikleri esas alınır;
// olağan kararlarda ikinci toplantıda katılanlar esas alınır.
func EvaluateMajority(
	code string,
	requiredRatio float64,
	callNumber int,
	totalUnits int, totalShare float64,
	attendedUnits int, attendedShare float64,
	votesFor int, shareFor float64,
	legalBasis string,
) models.MajorityResult {
	res := models.MajorityResult{
		RequiredCode:  code,
		RequiredRatio: requiredRatio,
		LegalBasis:    legalBasis,
	}

	baseUnits := totalUnits
	baseShare := totalShare
	baseLabel := "tüm kat malikleri"

	// Olağan kararlarda ikinci toplantının paydası katılanlardır.
	if code == "" && callNumber >= 2 {
		baseUnits = attendedUnits
		baseShare = attendedShare
		baseLabel = "toplantıya katılanlar"
	}
	if code == "" {
		requiredRatio = 0.5
		res.RequiredRatio = requiredRatio
		if res.LegalBasis == "" {
			res.LegalBasis = "KMK m.30 — olağan kararlarda salt çoğunluk"
		}
	}

	if baseUnits <= 0 || baseShare <= 0 {
		res.Explanation = "Karşılaştırma tabanı sıfır; nisap değerlendirilemez."
		return res
	}

	res.ByCountRatio = float64(votesFor) / float64(baseUnits)
	res.ByShareRatio = shareFor / baseShare

	// Oybirliği: hem sayı hem arsa payı bakımından tamamı.
	if requiredRatio >= 1.0 {
		res.Accepted = votesFor >= baseUnits && shareFor >= baseShare
		if res.Accepted {
			res.Explanation = fmt.Sprintf("Oybirliği sağlandı (%d/%d bağımsız bölüm).", votesFor, baseUnits)
		} else {
			res.Explanation = fmt.Sprintf(
				"Oybirliği SAĞLANMADI: %d/%d bağımsız bölüm kabul oyu verdi.", votesFor, baseUnits)
		}
		return res
	}

	// Salt çoğunluk ve üstü nisaplar: "yarıdan fazla" / "beşte dört" → kesin büyüklük.
	byCount := float64(votesFor) > requiredRatio*float64(baseUnits)
	byShare := shareFor > requiredRatio*baseShare
	// 4/5 gibi nisaplarda tam eşitlik de kabul edilir (beşte dördü "kadar" değil "en az").
	if requiredRatio > 0.5 {
		byCount = float64(votesFor) >= requiredRatio*float64(baseUnits)
		byShare = shareFor >= requiredRatio*baseShare
	}
	res.Accepted = byCount && byShare

	if res.Accepted {
		res.Explanation = fmt.Sprintf(
			"Kabul edildi: %d kabul oyu / %s %d bağımsız bölüm (%.1f%%), arsa payı %.2f/%.2f (%.1f%%); "+
				"aranan oran %.1f%%.",
			votesFor, baseLabel, baseUnits, res.ByCountRatio*100,
			shareFor, baseShare, res.ByShareRatio*100, requiredRatio*100)
	} else {
		missing := "sayı ve arsa payı"
		if byCount && !byShare {
			missing = "arsa payı"
		} else if !byCount && byShare {
			missing = "bağımsız bölüm sayısı"
		}
		res.Explanation = fmt.Sprintf(
			"REDDEDİLDİ: %s bakımından aranan %.1f%% oranına ulaşılmadı "+
				"(%d kabul oyu / %s %d bağımsız bölüm, arsa payı %.2f/%.2f).",
			missing, requiredRatio*100, votesFor, baseLabel, baseUnits, shareFor, baseShare)
	}
	return res
}
