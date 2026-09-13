# Migration çalıştırıcısı — tek seferlik (one-shot) kap.
#
# NEDEN AYRI BİR KAP:
# Migration'lar daha önce PostgreSQL'in `/docker-entrypoint-initdb.d` mekanizmasıyla
# uygulanıyordu. O mekanizma yalnızca veri dizini BOŞKEN çalışır; yani mevcut bir
# veritabanına yeni migration uygulanamıyordu ve hangi sürümün uygulandığı
# bilinmiyordu. Artık migration'lar bu kapta `cmd/migrate` ile uygulanır:
# sürüm takibi, advisory lock, sağlama denetimi ve migration başına transaction ile.

FROM golang:1.24-alpine AS builder
WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 go build -o /out/migrate ./cmd/migrate

FROM alpine:3.20
RUN adduser -D -u 10001 migrator
WORKDIR /app
COPY --from=builder /out/migrate /app/migrate
COPY migrations /app/migrations
USER migrator
ENTRYPOINT ["/app/migrate", "-dir", "/app/migrations"]
