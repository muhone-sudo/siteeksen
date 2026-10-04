package middleware

// İstek metrikleri (todo 3.6). Harici bağımlılık olmadan Prometheus metin
// biçiminde /metrics ucu sunar: rota şablonu + yöntem + durum sınıfı başına
// istek sayısı ve gecikme histogramı, ayrıca 5xx sayısı.
//
// Ham yol yazılmaz (yalnızca /residents/:id gibi şablon): yol kişisel veri
// taşıyabilir. /metrics gateway'den GEÇMEZ (gateway yalnızca /api/v1 ön eklerini
// yönlendirir); yalnızca küme içinden kazınır.

import (
	"fmt"
	"net/http"
	"sort"
	"strings"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
)

// latencyBuckets saniye cinsinden histogram sınırlarıdır.
var latencyBuckets = []float64{0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5}

type metricKey struct{ route, method, class string }

type metricVal struct {
	count   uint64
	sum     float64
	buckets []uint64
}

// Metrics, tek servisin istek metrikleridir.
type Metrics struct {
	service string
	start   time.Time
	mu      sync.Mutex
	data    map[metricKey]*metricVal
}

// NewMetrics yeni metrik deposu üretir.
func NewMetrics(service string) *Metrics {
	return &Metrics{service: service, start: time.Now(), data: map[metricKey]*metricVal{}}
}

// Middleware her isteği sayar.
func (m *Metrics) Middleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		c.Next()
		route := c.FullPath()
		if route == "" {
			route = "unmatched"
		}
		if route == "/metrics" {
			return
		}
		m.Observe(route, c.Request.Method, c.Writer.Status(), time.Since(start))
	}
}

// Observe tek gözlemi ekler.
func (m *Metrics) Observe(route, method string, status int, d time.Duration) {
	k := metricKey{route: route, method: method, class: fmt.Sprintf("%dxx", status/100)}
	sec := d.Seconds()
	m.mu.Lock()
	defer m.mu.Unlock()
	v := m.data[k]
	if v == nil {
		v = &metricVal{buckets: make([]uint64, len(latencyBuckets))}
		m.data[k] = v
	}
	v.count++
	v.sum += sec
	for i, b := range latencyBuckets {
		if sec <= b {
			v.buckets[i]++
		}
	}
}

func esc(s string) string { return strings.NewReplacer(`\`, `\\`, `"`, `\"`, "\n", `\n`).Replace(s) }

// Handler Prometheus metin biçiminde yazar.
func (m *Metrics) Handler() gin.HandlerFunc {
	return func(c *gin.Context) {
		m.mu.Lock()
		keys := make([]metricKey, 0, len(m.data))
		for k := range m.data {
			keys = append(keys, k)
		}
		sort.Slice(keys, func(i, j int) bool {
			if keys[i].route != keys[j].route {
				return keys[i].route < keys[j].route
			}
			if keys[i].method != keys[j].method {
				return keys[i].method < keys[j].method
			}
			return keys[i].class < keys[j].class
		})
		var b strings.Builder
		svc := esc(m.service)
		fmt.Fprintf(&b, "# HELP siteeksen_uptime_seconds Servisin çalışma süresi.\n# TYPE siteeksen_uptime_seconds gauge\n")
		fmt.Fprintf(&b, "siteeksen_uptime_seconds{service=\"%s\"} %.0f\n", svc, time.Since(m.start).Seconds())
		fmt.Fprintf(&b, "# HELP siteeksen_http_requests_total İstek sayısı.\n# TYPE siteeksen_http_requests_total counter\n")
		for _, k := range keys {
			fmt.Fprintf(&b, "siteeksen_http_requests_total{service=\"%s\",route=\"%s\",method=\"%s\",status=\"%s\"} %d\n",
				svc, esc(k.route), k.method, k.class, m.data[k].count)
		}
		fmt.Fprintf(&b, "# HELP siteeksen_http_request_duration_seconds İstek süresi.\n# TYPE siteeksen_http_request_duration_seconds histogram\n")
		for _, k := range keys {
			v := m.data[k]
			labels := fmt.Sprintf("service=\"%s\",route=\"%s\",method=\"%s\",status=\"%s\"", svc, esc(k.route), k.method, k.class)
			for i, le := range latencyBuckets {
				fmt.Fprintf(&b, "siteeksen_http_request_duration_seconds_bucket{%s,le=\"%g\"} %d\n", labels, le, v.buckets[i])
			}
			fmt.Fprintf(&b, "siteeksen_http_request_duration_seconds_bucket{%s,le=\"+Inf\"} %d\n", labels, v.count)
			fmt.Fprintf(&b, "siteeksen_http_request_duration_seconds_sum{%s} %.6f\n", labels, v.sum)
			fmt.Fprintf(&b, "siteeksen_http_request_duration_seconds_count{%s} %d\n", labels, v.count)
		}
		m.mu.Unlock()
		c.Data(http.StatusOK, "text/plain; version=0.0.4; charset=utf-8", []byte(b.String()))
	}
}
