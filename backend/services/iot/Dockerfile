FROM golang:1.21-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -o /iot-service ./services/iot

FROM alpine:3.19

RUN apk --no-cache add ca-certificates

COPY --from=builder /iot-service /iot-service

EXPOSE 8084

CMD ["/iot-service"]
