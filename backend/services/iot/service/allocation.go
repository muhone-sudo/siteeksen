// Package service, tüketim gideri paylaştırma hesaplarını içerir.
package service

import (
	"errors"

	"github.com/shopspring/decimal"
	"github.com/siteeksen/backend/pkg/money"
)

var (
	// ErrNoBasis, dağıtım için ne tüketim ne alan bulunduğunda döner.
	ErrNoBasis = errors.New("dağıtım için tüketim ve kullanım alanı verisi yok")
	// ErrInvalidShares, paylar toplamı 1 değilse döner.
	ErrInvalidShares = errors.New("paylaşım oranları toplamı 1 olmalıdır")
)

// UnitBasis, bir bağımsız bölümün dağıtım ölçütleridir.
type UnitBasis struct {
	UnitID      string
	UnitName    string
	Consumption decimal.Decimal
	UsableArea  decimal.Decimal
}

// UnitAllocation, bir bağımsız bölüme düşen paydır. Tutarlar KURUŞ'tur.
type UnitAllocation struct {
	UnitID           string `json:"unit_id"`
	UnitName         string `json:"unit_name"`
	Consumption      string `json:"consumption"`
	UsableArea       string `json:"usable_area"`
	ConsumptionShare int64  `json:"consumption_share_kurus"`
	AreaShare        int64  `json:"area_share_kurus"`
	TotalKurus       int64  `json:"total_kurus"`
	TotalTRY         string `json:"total_try"`
}

// Allocation, bir dönemin paylaştırma sonucudur.
type Allocation struct {
	TotalKurus           int64            `json:"total_kurus"`
	ConsumptionPartKurus int64            `json:"consumption_part_kurus"`
	AreaPartKurus        int64            `json:"area_part_kurus"`
	ConsumptionSharePct  string           `json:"consumption_share_pct"`
	AreaSharePct         string           `json:"area_share_pct"`
	Units                []UnitAllocation `json:"units"`
	TotalConsumption     string           `json:"total_consumption"`
	TotalUsableArea      string           `json:"total_usable_area"`
	UnitsWithoutReading  int              `json:"units_without_reading"`
	UnitsWithEstimated   int              `json:"units_with_estimated_reading"`
}

// AllocateHeating, merkezi ısıtma giderini mevzuata göre paylaştırır.
//
// Dayanak: "Merkezi Isıtma ve Sıhhi Sıcak Su Sistemlerinde Isınma ve Sıhhi Sıcak
// Su Giderlerinin Paylaştırılmasına İlişkin Yönetmelik" (RG 14.04.2008/26847).
// Gider iki bileşene ayrılır:
//   - TÜKETİM payı: sayaç/pay ölçer okumalarına göre (varsayılan %70)
//     Yalnızca fiilen tüketim yapan bölümler bu paya girer.
//   - SABİT pay: kullanım alanına göre (varsayılan %30)
//     Hiç tüketim yapmayan bölüm de bu payı öder — ısı komşu bölümlerden geçer.
//
// Oranlar KODA GÖMÜLMEZ; çağıran taraf `legal_parameters` üzerinden verir
// (HEATING_CONSUMPTION_SHARE / HEATING_AREA_SHARE). İkisinin toplamı 1 olmalıdır.
//
// Dağıtım tam sayı kuruş üzerinden, en büyük kalan yöntemiyle yapılır: payların
// toplamı toplam gidere BİREBİR eşittir, kuruş kaybı ya da fazlası olmaz.
//
// Tüketim toplamı sıfırsa (kimse ısıtma kullanmamışsa) tüketim payı da alana
// göre dağıtılır — aksi hâlde giderin %70'i dağıtılmadan ortada kalırdı.
func AllocateHeating(total money.Kurus, consumptionShare, areaShare decimal.Decimal, units []UnitBasis) (*Allocation, error) {
	if !consumptionShare.Add(areaShare).Equal(decimal.NewFromInt(1)) {
		return nil, ErrInvalidShares
	}
	if len(units) == 0 {
		return nil, ErrNoBasis
	}

	totalConsumption := decimal.Zero
	totalArea := decimal.Zero
	for _, u := range units {
		totalConsumption = totalConsumption.Add(u.Consumption)
		totalArea = totalArea.Add(u.UsableArea)
	}
	if totalArea.LessThanOrEqual(decimal.Zero) {
		return nil, ErrNoBasis
	}

	// Giderin tüketim ve sabit bileşenlerine ayrılması da kuruş bazlıdır:
	// önce tüketim payı hesaplanır, kalanı sabit paya verilir. Böylece iki
	// bileşenin toplamı her zaman toplam gidere eşit kalır.
	consumptionPart := money.Kurus(
		decimal.NewFromInt(int64(total)).Mul(consumptionShare).Round(0).IntPart())
	if consumptionPart > total {
		consumptionPart = total
	}
	areaPart := total - consumptionPart

	// Tüketim yoksa tüketim payı da alana göre dağıtılır.
	consumptionByArea := totalConsumption.LessThanOrEqual(decimal.Zero)

	consShares := make([]money.Share, 0, len(units))
	areaShares := make([]money.Share, 0, len(units))
	for _, u := range units {
		w := u.Consumption
		if consumptionByArea {
			w = u.UsableArea
		}
		consShares = append(consShares, money.Share{Key: u.UnitID, Weight: w})
		areaShares = append(areaShares, money.Share{Key: u.UnitID, Weight: u.UsableArea})
	}

	consResult, err := money.Distribute(consumptionPart, consShares)
	if err != nil {
		return nil, err
	}
	areaResult, err := money.Distribute(areaPart, areaShares)
	if err != nil {
		return nil, err
	}

	consByUnit := map[string]money.Kurus{}
	for _, s := range consResult {
		consByUnit[s.Key] = s.Amount
	}
	areaByUnit := map[string]money.Kurus{}
	for _, s := range areaResult {
		areaByUnit[s.Key] = s.Amount
	}

	alloc := &Allocation{
		TotalKurus:           int64(total),
		ConsumptionPartKurus: int64(consumptionPart),
		AreaPartKurus:        int64(areaPart),
		ConsumptionSharePct:  consumptionShare.Mul(decimal.NewFromInt(100)).StringFixed(2),
		AreaSharePct:         areaShare.Mul(decimal.NewFromInt(100)).StringFixed(2),
		TotalConsumption:     totalConsumption.String(),
		TotalUsableArea:      totalArea.String(),
	}

	for _, u := range units {
		cs := consByUnit[u.UnitID]
		as := areaByUnit[u.UnitID]
		sum := cs + as
		alloc.Units = append(alloc.Units, UnitAllocation{
			UnitID:           u.UnitID,
			UnitName:         u.UnitName,
			Consumption:      u.Consumption.String(),
			UsableArea:       u.UsableArea.String(),
			ConsumptionShare: int64(cs),
			AreaShare:        int64(as),
			TotalKurus:       int64(sum),
			TotalTRY:         sum.TRY().StringFixed(2),
		})
	}
	return alloc, nil
}

// AllocateByConsumption, su/elektrik/gaz gibi giderleri YALNIZCA tüketime göre
// paylaştırır. Bu giderlerde sabit pay yoktur: komşunun suyu kimsenin dairesini
// ısıtmaz, bu yüzden tüketmeyen ödemez.
//
// Tüketim toplamı sıfırsa dağıtım yapılmaz — sıfır tüketimde fatura üretmek,
// dayanağı olmayan bir borç yaratır.
func AllocateByConsumption(total money.Kurus, units []UnitBasis) (*Allocation, error) {
	if len(units) == 0 {
		return nil, ErrNoBasis
	}
	totalConsumption := decimal.Zero
	for _, u := range units {
		totalConsumption = totalConsumption.Add(u.Consumption)
	}
	if totalConsumption.LessThanOrEqual(decimal.Zero) {
		return nil, ErrNoBasis
	}

	shares := make([]money.Share, 0, len(units))
	for _, u := range units {
		shares = append(shares, money.Share{Key: u.UnitID, Weight: u.Consumption})
	}
	result, err := money.Distribute(total, shares)
	if err != nil {
		return nil, err
	}
	byUnit := map[string]money.Kurus{}
	for _, s := range result {
		byUnit[s.Key] = s.Amount
	}

	alloc := &Allocation{
		TotalKurus:           int64(total),
		ConsumptionPartKurus: int64(total),
		AreaPartKurus:        0,
		ConsumptionSharePct:  "100.00",
		AreaSharePct:         "0.00",
		TotalConsumption:     totalConsumption.String(),
		TotalUsableArea:      "0",
	}
	for _, u := range units {
		amt := byUnit[u.UnitID]
		alloc.Units = append(alloc.Units, UnitAllocation{
			UnitID:           u.UnitID,
			UnitName:         u.UnitName,
			Consumption:      u.Consumption.String(),
			UsableArea:       u.UsableArea.String(),
			ConsumptionShare: int64(amt),
			AreaShare:        0,
			TotalKurus:       int64(amt),
			TotalTRY:         amt.TRY().StringFixed(2),
		})
	}
	return alloc, nil
}
