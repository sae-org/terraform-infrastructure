terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# configuring aws provider 
provider "aws" {
  region = "us-east-1"
  profile = "tf"
}

# KMS module 
module "kms" {
  source   = "git::https://github.com/sae-org/terraform-modules.git//modules/kms?ref=main"
}

# Creating s3 bucket with kms to use as backend 
module "s3" {
  source   = "git::https://github.com/sae-org/terraform-modules.git//modules/s3?ref=main"
  proj_prefix = "clock-cloudfront"
  kms_key_arn = module.kms.kms_key_arn
  users = ["Saeeda", "terraform"]
}
