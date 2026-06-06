FROM golang:1.24-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -o /energy_analytics-service ./services/energy_analytics

FROM alpine:3.19

RUN apk --no-cache add ca-certificates tzdata

WORKDIR /app

COPY --from=builder /energy_analytics-service .
RUN chmod +x ./energy_analytics-service

CMD ["./energy_analytics-service"]
