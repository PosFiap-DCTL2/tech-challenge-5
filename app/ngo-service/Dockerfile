FROM python:3.9-slim AS builder

WORKDIR /app
COPY requirements.txt .

# Instala as dependências numa pasta local do usuário
RUN pip install --user --no-cache-dir -r requirements.txt

# ==========================================
# ESTÁGIO 2: Produção (Imagem limpa e leve)
# ==========================================
FROM python:3.9-slim

WORKDIR /app

# Copia APENAS as dependências prontas do estágio 1 (Multi-stage build)
COPY --from=builder /root/.local /root/.local

# Copia o código-fonte da nossa aplicação
COPY . .

# Variáveis de ambiente obrigatórias
ENV PATH=/root/.local/bin:$PATH
ENV PORT=8081
ENV OTEL_SERVICE_NAME="ngo-service"

# Expõe a porta que o edital pediu
EXPOSE 8081

# O comando mágico: Inicia o OpenTelemetry vigiando o Gunicorn
CMD ["opentelemetry-instrument", "gunicorn", "--bind", "0.0.0.0:8081", "--workers", "2", "--threads", "4", "app:app"]