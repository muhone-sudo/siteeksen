FROM golang:1.21-alpine AS builder

WORKDIR /app

# Bağımlılıkları kopyala
COPY go.mod go.sum ./
RUN go mod download

# Kaynak kodları kopyala
COPY . .

# Identity service'i derle
RUN CGO_ENABLED=0 GOOS=linux go build -o /identity-service ./services/identity

# Runtime image
FROM alpine:3.19

RUN apk --no-cache add ca-certificates tzdata

WORKDIR /app

COPY --from=builder /identity-service .

EXPOSE 8081

CMD ["./identity-service"]
