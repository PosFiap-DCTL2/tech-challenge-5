variable "instance_types" {
  description = "Variavel para troca de tipo de instanca"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "lab_role_arn" {
  description = "ARN of the AWS Academy LabRoles"
  type        = string
  default     = "arn:aws:iam::082722225763:role/admin"
}

variable "subnets" {
  description = "Lista de subnets do EKS"
  type        = list(string)
}

variable "grupodeseguranca" {
  description = "Security Group ID do EKS"
  type        = string
}