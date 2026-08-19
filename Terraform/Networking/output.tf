output "private_subnet_ids" {
  value = [
    aws_subnet.subnetprivada1.id,
    aws_subnet.subnetprivada2.id
  ]
}

output "vpc_id" {
  value = aws_vpc.vpcpos.id
}

output "rds_config" {
  description = "Configurações necessárias para o RDS"
  value = {
    subnet_group_id   = aws_db_subnet_group.rds_subnet_group.id
    security_group_id = aws_security_group.rds.id
  }
}

output "eks_subnet_ids" {
  description = "Subnets do EKS"
  value = [
    aws_subnet.subnetprivada1.id,
    aws_subnet.subnetprivada2.id,
    aws_subnet.subnetpublica1.id,
    aws_subnet.subnetpublica2.id
  ]
}

output "eks_security_group_id" {
  description = "ID do grupo de segurança para o EKS"
  value       = aws_security_group.eks.id
}