terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment and configure once you have an S3 state bucket
  # backend "s3" {
  #   bucket  = "ajayshandbook-terraform-state"
  #   key     = "stable/us-east-2/mgmt-cluster/terraform.tfstate"
  #   region  = "us-east-2"
  #   encrypt = true
  # }
}

provider "aws" {
  region  = "us-east-2"
  profile = "awsadmin"

  default_tags {
    tags = {
      Environment = "stable"
      Project     = "ajayshandbook"
      Cluster     = "mgmt-cluster"
      ManagedBy   = "terraform"
    }
  }
}
