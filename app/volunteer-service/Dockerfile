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

RUN groupadd --gid 1001 appgroup && \
    useradd --uid 1001 --gid appgroup --no-create-home --shell /sbin/nologin appuser
USER appuser

ENV DD_SERVICE="volunteer-service"
ENV DD_ENV="hackathon"
ENV DD_VERSION="1.0.0"

EXPOSE 8083

CMD ["ddtrace-run", "python", "app.py"]