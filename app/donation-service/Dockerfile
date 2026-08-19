# Stage 1: Build binary
FROM golang:1.24-alpine AS builder

WORKDIR /app

RUN apk add --no-cache git ca-certificates

COPY go.mod go.sum* ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o donation-service .

# Stage 2: Production Minimal Image (Non-root user)
FROM alpine:3.19

RUN apk --no-cache add ca-certificates tzdata

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

COPY --from=builder /app/donation-service .

RUN chown -R appuser:appgroup /app

# Variáveis de identificação do Datadog
ENV DD_SERVICE="donation-service"
ENV DD_ENV="hackathon"
ENV DD_VERSION="1.0.0"

USER appuser

EXPOSE 8082

ENTRYPOINT ["/app/donation-service"]
