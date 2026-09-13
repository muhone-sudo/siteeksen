FROM golang:1.24-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -o /meeting_wizard-service ./services/meeting_wizard

FROM alpine:3.19

RUN apk --no-cache add ca-certificates tzdata

WORKDIR /app

COPY --from=builder /meeting_wizard-service .
RUN chmod +x ./meeting_wizard-service

CMD ["./meeting_wizard-service"]
