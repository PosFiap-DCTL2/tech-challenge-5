# ==========================================
# ESTÁGIO 1: Builder (Instala dependências)
# ==========================================
FROM python:3.9-slim AS builder

WORKDIR /app
COPY requirements.txt .

# Instala as dependências da aplicação e do ecossistema OpenTelemetry
RUN pip install --user --no-cache-dir -r requirements.txt && \
    pip install --user --no-cache-dir \
    opentelemetry-api \
    opentelemetry-sdk \
    opentelemetry-instrumentation \
    opentelemetry-instrumentation-flask \
    opentelemetry-exporter-otlp

# ==========================================
# ESTÁGIO 2: Produção (Imagem limpa e leve)
# ==========================================
FROM python:3.9-slim

WORKDIR /app

# Copia APENAS as dependências prontas do estágio 1 (Multi-stage build)
COPY --from=builder /root/.local /root/.local

# Copia o código-fonte da aplicação
COPY . .

# Garante acesso aos executáveis instalados pelo pip (--user)
ENV PATH=/root/.local/bin:$PATH
ENV PORT=8081

# Variáveis para Datadog APM & AIOps (Watchdog / Applied Intelligence)
ENV DD_SERVICE="ngo-service" \
    DD_ENV="hackathon" \
    DD_VERSION="1.0.0" \
    DD_LOGS_INJECTION="true"

# Variáveis para OpenTelemetry (OTel / OTLP) e comunicação com Grafana Alloy
ENV OTEL_SERVICE_NAME="ngo-service" \
    OTEL_EXPORTER_OTLP_ENDPOINT="http://alloy.alloy.svc.cluster.local:4318" \
    OTEL_EXPORTER_OTLP_PROTOCOL="http/protobuf" \
    DD_TRACE_OTLP_ENABLED="true" \
    OTEL_RESOURCE_ATTRIBUTES="deployment.environment=hackathon,service.version=1.0.0"

# Expõe a porta que o edital pediu
EXPOSE 8081

# O comando mágico: Inicia a aplicação com o agente automático do OpenTelemetry
CMD ["opentelemetry-instrument", "gunicorn", "--bind", "0.0.0.0:8081", "--workers", "2", "--threads", "4", "app:app"]