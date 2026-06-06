FROM golang:1.24-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -o /smart_collection-service ./services/smart_collection

FROM alpine:3.19

RUN apk --no-cache add ca-certificates tzdata

WORKDIR /app

COPY --from=builder /smart_collection-service .
RUN chmod +x ./smart_collection-service

CMD ["./smart_collection-service"]
