resource "aws_default_vpc" "hackathonvpc" {
  tags = {
    Name = "hackathonvpc"
  }
}

#### SUBNETS ####

resource "aws_subnet" "subnetpublica01" {
  vpc_id     = aws_default_vpc.hackathonvpc.id
  cidr_block = "172.16.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = var.AZ[0]
}

resource "aws_subnet" "subnetpublica02" {
  vpc_id     = aws_default_vpc.hackathonvpc.id
  cidr_block = "172.16.2.0/24"
  map_public_ip_on_launch = true
  availability_zone = var.AZ[1]
}

resource "aws_subnet" "subnetprivada01" {
  vpc_id     = aws_default_vpc.hackathonvpc.id
  cidr_block = "172.16.3.0/24"
  map_public_ip_on_launch = false
  availability_zone = var.AZ[0]
}

resource "aws_subnet" "subnetprivada02" {
  vpc_id     = aws_default_vpc.hackathonvpc.id
  cidr_block = "172.16.4.0/24"
  map_public_ip_on_launch = false
  availability_zone = var.AZ[1]
}

#### DB Subnet Group ####

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rdssubnetgroup"
  subnet_ids = [aws_subnet.subnetpublica1.id, aws_subnet.subnetpublica2.id]
}

### Nat Gateway ###

resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.subnetpublica1.id
}

### Tabela de Roteamento Pública ###

resource "aws_route_table" "publica" {
  vpc_id = aws_vpc.vpcpos.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "tabeladerotapublica1" {
  subnet_id      = aws_subnet.subnetpublica1.id
  route_table_id = aws_route_table.publica.id
}

resource "aws_route_table_association" "tabeladerotapublica2" {
  subnet_id      = aws_subnet.subnetpublica2.id
  route_table_id = aws_route_table.publica.id
}

### Tabela de Roteamento Privada ###

resource "aws_route_table" "privada" {
  vpc_id = aws_vpc.vpcpos.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

resource "aws_route_table_association" "tabeladerotaprivada1" {
  subnet_id      = aws_subnet.subnetprivada1.id
  route_table_id = aws_route_table.privada.id
}

resource "aws_route_table_association" "tabeladerotaprivada2" {
  subnet_id      = aws_subnet.subnetprivada2.id
  route_table_id = aws_route_table.privada.id
}

### Gateway de internet ###

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpcpos.id
}

### Security Group ###

resource "aws_security_group" "eks" {
  name        = "eks-security-group"
  description = "Security Group do EKS"
  vpc_id      = aws_vpc.vpcpos.id

  egress {
    description = "EKS pode sair para qualquer destino"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds" {
  name        = "rds-security-group"
  description = "Security Group do RDS"
  vpc_id      = aws_vpc.vpcpos.id

  ingress {
    description     = "Postgres somente do EKS"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    
    security_groups = [var.eks_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}