terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

#Calling VPC creation
module "vpc" {
  source = "../modules/aws_vpc"

  vpc_name   = "FlyingRaijinUnit-vpc"
  cidr_block = "10.0.0.0/16"

  public_subnets = {
    "subnet-a" = "10.0.1.0/24"
  }

  private_subnets = {
    "subnet-a" = "10.0.101.0/24"
  }
  availability_zones = {
    "subnet-a" = "ap-south-1a"
  }

  enable_private_subnets = false

  common_tags = {
    environment = "Development"
  }
}