resource "aws_vpc" "hackathonvpc" {
  tags = {
    Project     = "SolidaryTech"
    Environment = "Production"
    CostCenter  = "VPC-Core"
  }
}

#### SUBNETS ####

resource "aws_subnet" "subnetpublica1" {
  vpc_id                  = aws_vpc.hackathonvpc.id
  cidr_block              = "172.16.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zones[0]

  tags = {
    Name        = "SolidaryTech"
    Environment = "Production"
    CostCenter  = "VPC-subnet-publica1"
  }
}

resource "aws_subnet" "subnetpublica2" {
  vpc_id                  = aws_vpc.hackathonvpc.id
  cidr_block              = "172.16.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zones[1]

  tags = {
    Name        = "SolidaryTech"
    Environment = "Production"
    CostCenter  = "VPC-subnet-publica2"
  }
}

resource "aws_subnet" "subnetprivada1" {
  vpc_id                  = aws_vpc.hackathonvpc.id
  cidr_block              = "172.16.3.0/24"
  map_public_ip_on_launch = false
  availability_zone       = var.availability_zones[0]

  tags = {
    Name        = "SolidaryTech"
    Environment = "Production"
    CostCenter  = "VPC-subnet-privada01"
  }
}

resource "aws_subnet" "subnetprivada2" {
  vpc_id                  = aws_vpc.hackathonvpc.id
  cidr_block              = "172.16.4.0/24"
  map_public_ip_on_launch = false
  availability_zone       = var.availability_zones[1]

  tags = {
    Name        = "SolidaryTech"
    Environment = "Production"
    CostCenter  = "VPC-subnet-privada2"
  }
}

#### DB Subnet Group ####

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rdssubnetgroup"
  subnet_ids = [aws_subnet.subnetpublica1.id, aws_subnet.subnetpublica2.id]
}

### Nat Gateway ###

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name        = "SolidaryTech"
    Environment = "Production"
    CostCenter  = "VPC-NAT"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.subnetpublica1.id

}

### Tabela de Roteamento Pública ###

resource "aws_route_table" "publica" {
  vpc_id = aws_vpc.hackathonvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name        = "SolidaryTech"
    Environment = "Production"
    CostCenter  = "VPC-RouteTable-Publica"
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
  vpc_id = aws_vpc.hackathonvpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name        = "SolidaryTech"
    Environment = "Production"
    CostCenter  = "VPC-RouteTable-Privada"
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
  vpc_id = aws_vpc.hackathonvpc.id

  tags = {
    Name        = "SolidaryTech"
    Environment = "Production"
    CostCenter  = "VPC-Internet-Gateway"
  }
}

### Security Group ###

resource "aws_security_group" "eks" {
  name        = "eks-security-group"
  description = "Security Group do EKS"
  vpc_id      = aws_vpc.hackathonvpc.id

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
  vpc_id      = aws_vpc.hackathonvpc.id

  ingress {
    description = "Postgres somente do EKS"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"

    security_groups = [var.eks_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}