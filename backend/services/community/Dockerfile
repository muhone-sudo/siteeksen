FROM golang:1.21-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -o /community-service ./services/community

FROM alpine:3.19

RUN apk --no-cache add ca-certificates

COPY --from=builder /community-service /community-service

EXPOSE 8083

CMD ["/community-service"]
