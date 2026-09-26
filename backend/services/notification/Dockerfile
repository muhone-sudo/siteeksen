# notification-service — Bu dosya backend/scripts/gen-deploy.py ile ÜRETİLİR — elle düzenlemeyin.
#
# Root olmayan kullanıcıyla çalışır; ikili, kaynak kodu içermeyen küçük bir
# imajdadır. Port ve GIN_MODE burada sabitlenir; gizli değerler çalışma
# anında ortam değişkeniyle verilir (imaja GİRMEZ).
FROM golang:1.24-alpine AS builder
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/app ./services/notification

FROM alpine:3.20
RUN apk --no-cache add ca-certificates tzdata && addgroup -S app && adduser -S -G app -u 10001 app
WORKDIR /app
COPY --from=builder /out/app /app/notification-service
USER app
ENV PORT=8085 GIN_MODE=release
EXPOSE 8085
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget -qO- http://127.0.0.1:8085/health >/dev/null || exit 1
ENTRYPOINT ["/app/notification-service"]
