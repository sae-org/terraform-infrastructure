# Store Terraform state in S3 and enable native S3 locking
terraform {
  backend "s3" {
    bucket       = "sae-s3-terraform-backend"
    key          = "dev/us-east-1/s3/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# Configure AWS region
provider "aws" {
  region = "us-east-1"
}

