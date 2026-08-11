variable "availability_zones" {
  description = "Availability Zones usadas pelas subnets do EKS (us-east-1)"
  type        = list(string)
  default = [
    "us-east-1a",
    "us-east-1b"
  ]
}

variable "eks_security_group_id" {
  description = "Security Group criado automaticamente pelo EKS"
  type        = string
}