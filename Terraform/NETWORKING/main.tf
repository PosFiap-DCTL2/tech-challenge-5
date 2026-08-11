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