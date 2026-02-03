FROM golang:1.24-alpine AS builder

WORKDIR /app

# Sadece main dosya olduğu için direkt kopyalayıp build ediyoruz
COPY cmd/gateway/main.go .

RUN go build -o /gateway main.go

FROM alpine:3.19

WORKDIR /app

COPY --from=builder /gateway .

EXPOSE 8888

CMD ["./gateway"]
