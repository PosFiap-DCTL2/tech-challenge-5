# Donation Service

Microsserviço de processamento de doações desenvolvido em Go 1.21.

## Tecnologias
- Go 1.21
- PostgreSQL
- AWS SQS
- Prometheus Metrics (`/metrics`)

## CI/CD Pipeline
- Security Scan (gosec SAST & Trivy SCA)
- Static Analysis (golangci-lint)
- Build & Unit Tests
- Docker Build & Push to AWS ECR
