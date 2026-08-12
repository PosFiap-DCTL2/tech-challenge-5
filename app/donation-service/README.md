# Donation Service

Microsserviço de processamento de doações desenvolvido em Go 1.21.

## Arquitetura & Tecnologias
- Linguagem: Go 1.21
- Banco de Dados: PostgreSQL (`donation_db`)
- Mensageria: AWS SQS (`solidary-donations`)
- Observabilidade: Prometheus Metrics (`/metrics`)

## Esteira CI/CD
- Security Scan: SAST (gosec) e SCA (Trivy & govulncheck)
- Análise Estática: golangci-lint
- Testes Unitários: `go test -v ./...`
- Containerization: Multi-stage Docker Build
- Deployment: AWS ECR (`tech5/donation-service`)
