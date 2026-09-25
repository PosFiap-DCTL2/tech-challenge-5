## Stage 1: Build binary
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

RUN addgroup -S -g 1001 appgroup && adduser -S -u 1001 -G appgroup appuser

WORKDIR /app

COPY --from=builder /app/donation-service .

RUN chown -R appuser:appgroup /app

# Variáveis para Datadog APM & AIOps (Watchdog / Applied Intelligence)
ENV DD_SERVICE="donation-service" \
    DD_ENV="hackathon" \
    DD_VERSION="1.0.0" \
    DD_PROFILING_ENABLED="true" \
    DD_LOGS_INJECTION="true" \
    DD_RUNTIME_METRICS_ENABLED="true" \
    DD_TRACE_PROPAGATION_STYLE="tracecontext,datadog" \
    DD_AGENT_HOST="alloy.alloy.svc.cluster.local" \
    DD_TRACE_AGENT_PORT="8126"    


USER 1001

EXPOSE 8082

ENTRYPOINT ["/app/donation-service"]

