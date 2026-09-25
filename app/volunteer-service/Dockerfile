# ==== Build stage ====

FROM python:3.9-slim as builder

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

## ==== Final stage ====

FROM python:3.9-slim

WORKDIR /app

COPY --from=builder /usr/local/lib/python3.9/site-packages /usr/local/lib/python3.9/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin
COPY app.py .
COPY generate-traffic.sh .

RUN groupadd --gid 1001 appgroup && \
    useradd --uid 1001 --gid appgroup --no-create-home --shell /sbin/nologin appuser
USER appuser

ENV DD_SERVICE="volunteer-service" \
    DD_ENV="hackathon" \
    DD_VERSION="1.0.0" \
    DD_LOGS_INJECTION="true"

ENV OTEL_SERVICE_NAME="volunteer-service" \
    OTEL_EXPORTER_OTLP_ENDPOINT="http://alloy.alloy.svc.cluster.local:4318" \
    OTEL_EXPORTER_OTLP_PROTOCOL="http/protobuf" \
    OTEL_TRACES_EXPORTER="otlp"

EXPOSE 8083

CMD ["opentelemetry-instrument", "gunicorn", "--bind", "0.0.0.0:8083", "--workers", "2", "--threads", "4", "app:app"]