variable "password" {
  description = "Senha do banco de dados"
  type        = string
  sensitive   = true
  default     = "SenhaForte123!"
}

variable "user" {
  description = "Usuário do banco de dados"
  type        = string
  sensitive   = true
  default     = "admin"
}

variable "instanceclass" {
  description = "Tipo de instância do banco de dados"
  type        = string
  default     = "db.t3.micro"
}

variable "network" {
  description = "Configurações de rede para o Redis"
  type = object({
    subnet_group_id   = string
    security_group_id = string
  })
}