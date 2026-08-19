terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

## Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

module "Networking" {
  source                = "./Networking"
  eks_security_group_id = module.EKS_cluster.cluster_security_group_id
}

module "EKS_cluster" {
  source           = "./EKS"
  subnets          = module.Networking.eks_subnet_ids
  grupodeseguranca = module.Networking.eks_security_group_id
}

module "ECR_donation_service" {
  source = "./ECR/donation-service"
}

module "ECR_ngo_service" {
  source = "./ECR/ngo-service"
}

module "ECR_volunteer_service" {
  source = "./ECR/volunteer-service"
}

module "dynamodb" {
  source = "./DYNAMODB"
}

module "SQS" {
  source = "./SQS"
}

module "RDS_donation_db" {
  source  = "./RDS/donationdb"
  network = module.Networking.rds_config
}

module "RDS_ngo_db" {
  source  = "./RDS/ngodb"
  network = module.Networking.rds_config
}


