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