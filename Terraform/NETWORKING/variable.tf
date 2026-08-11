variable "AZ" {
  description = "Zona de disponibilidade do banco de dados"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
}