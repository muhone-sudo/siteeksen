FROM golang:1.21-alpine AS builder

WORKDIR /app

# Bağımlılıkları kopyala
COPY go.mod go.sum ./
RUN go mod download

# Kaynak kodları kopyala
COPY . .

# Finance service'i derle
RUN CGO_ENABLED=0 GOOS=linux go build -o /finance-service ./services/finance

# Runtime image
FROM alpine:3.19

RUN apk --no-cache add ca-certificates tzdata

WORKDIR /app

COPY --from=builder /finance-service .

EXPOSE 8082

CMD ["./finance-service"]
