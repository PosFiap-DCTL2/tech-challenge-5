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

#module "EKS_cluster" {
#  source           = "./EKS"
#  subnets          = module.Networking.eks_subnet_ids
#  grupodeseguranca = module.Networking.eks_security_group_id
#}