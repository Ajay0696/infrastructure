terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

#########################################################
# VPC Module
#########################################################

module "vpc" {
  source = "../modules/aws_vpc"

  vpc_name   = "ajayshandbook-vpc"
  cidr_block = "10.0.0.0/16"

  azs = ["ap-south-1a", "ap-south-1b"]

  public_subnets = {
    "public-a" = "10.0.64.0/19"
    "public-b" = "10.0.96.0/19"
  }

  private_subnets = {
    "private-a" = "10.0.0.0/19"
    "private-b" = "10.0.32.0/19"
  }

  tags = {
    Environment = "dev"
    Project     = "ajayshandbook"
  }
}

#########################################################
# EKS Module
#########################################################

module "eks" {
  source = "../modules/aws_eks"

  region          = "ap-south-1"
  cluster_name    = "ajayshandbook-eks"
  k8s_version     = "1.34"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = concat(module.vpc.public_subnet_ids, module.vpc.private_subnet_ids)
  public_subnets  = module.vpc.public_subnet_ids
  private_subnets = module.vpc.private_subnet_ids

  node_groups = {
    traefikinternal = {
      instance_type = "t3a.medium"
      min_size      = 1
      max_size      = 1
      desired_size  = 1
      spot_enabled  = true
      subnet_type   = "private"
    }

    traefikexternal = {
      instance_type = "t3a.medium"
      min_size      = 1
      max_size      = 1
      desired_size  = 1
      spot_enabled  = true
      subnet_type   = "private"
    }

    workload = {
      instance_type = "t3a.medium"
      min_size      = 1
      max_size      = 3
      desired_size  = 2
      spot_enabled  = true
      subnet_type   = "private"
    }
  }

  tags = {
    Environment = "dev"
    Project     = "ajayshandbook"
  }
}

