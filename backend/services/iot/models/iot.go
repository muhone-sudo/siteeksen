package models

import "time"

// Meter - Sayaç modeli
type Meter struct {
	ID           string    `json:"id"`
	PropertyID   string    `json:"property_id"`
	UnitID       string    `json:"unit_id"`
	Type         string    `json:"type"` // HEAT, WATER_COLD, WATER_HOT, ELECTRIC, GAS
	SerialNumber string    `json:"serial_number"`
	Brand        string    `json:"brand"`
	Model        string    `json:"model"`
	InstalledAt  time.Time `json:"installed_at"`
	LastReading  float64   `json:"last_reading"`
	LastReadAt   time.Time `json:"last_read_at"`
	Status       string    `json:"status"` // ACTIVE, INACTIVE, FAULTY
}

// MeterReading - Sayaç okuması
type MeterReading struct {
	ID          string    `json:"id"`
	MeterID     string    `json:"meter_id"`
	Value       float64   `json:"value"`
	Consumption float64   `json:"consumption"` // Önceki okumadan fark
	PeriodYear  int       `json:"period_year"`
	PeriodMonth int       `json:"period_month"`
	ReadBy      string    `json:"read_by"` // user_id veya "SYSTEM"
	ReadAt      time.Time `json:"read_at"`
	ImageURL    string    `json:"image_url,omitempty"`
	IsEstimated bool      `json:"is_estimated"` // Tahmini mi?
}

// Sensor - Sensör modeli
type Sensor struct {
	ID            string    `json:"id"`
	PropertyID    string    `json:"property_id"`
	Type          string    `json:"type"` // TEMPERATURE, HUMIDITY, PRESSURE, SMOKE, WATER_LEAK
	Location      string    `json:"location"`
	SerialNumber  string    `json:"serial_number"`
	MinThreshold  *float64  `json:"min_threshold,omitempty"`
	MaxThreshold  *float64  `json:"max_threshold,omitempty"`
	Unit          string    `json:"unit"` // °C, %, Pa, etc.
	Status        string    `json:"status"` // ONLINE, OFFLINE, ERROR
	LastValue     float64   `json:"last_value"`
	LastUpdate    time.Time `json:"last_update"`
	BatteryLevel  *int      `json:"battery_level,omitempty"` // Kablosuz sensörler için
}

// SensorData - Sensör verisi
type SensorData struct {
	ID        string    `json:"id"`
	SensorID  string    `json:"sensor_id"`
	Value     float64   `json:"value"`
	Timestamp time.Time `json:"timestamp"`
}

// Alert - IoT uyarısı
type Alert struct {
	ID             string     `json:"id"`
	PropertyID     string     `json:"property_id"`
	SensorID       string     `json:"sensor_id,omitempty"`
	MeterID        string     `json:"meter_id,omitempty"`
	Type           string     `json:"type"` // HIGH_TEMP, LOW_TEMP, WATER_LEAK, SMOKE_DETECTED, etc.
	Message        string     `json:"message"`
	Severity       string     `json:"severity"` // INFO, WARNING, CRITICAL
	Value          float64    `json:"value"`
	Threshold      float64    `json:"threshold"`
	CreatedAt      time.Time  `json:"created_at"`
	Acknowledged   bool       `json:"acknowledged"`
	AcknowledgedBy string     `json:"acknowledged_by,omitempty"`
	AcknowledgedAt *time.Time `json:"acknowledged_at,omitempty"`
}

// ConsumptionSummary - Tüketim özeti
type ConsumptionSummary struct {
	PropertyID  string  `json:"property_id"`
	UnitID      string  `json:"unit_id,omitempty"`
	MeterType   string  `json:"meter_type"`
	PeriodYear  int     `json:"period_year"`
	PeriodMonth int     `json:"period_month"`
	Total       float64 `json:"total"`
	UnitPrice   float64 `json:"unit_price"`
	TotalCost   float64 `json:"total_cost"`
}
