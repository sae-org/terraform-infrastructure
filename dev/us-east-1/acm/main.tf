terraform {
  backend "s3" {
    bucket       = "sae-s3-terraform-backend"          
    key          = "dev/us-east-1/acm/terraform.tfstate" 
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

provider "aws" {
  region = "us-east-1"
  profile = "tf"
}

module "acm" {
  source   = "git::https://github.com/sae-org/terraform-modules.git//modules/acm?ref=main"
  acm_domains = ["*.saeeda.me", "saeeda.me"]
  validation_method = "DNS"
}

module "r53" {
  source   = "git::https://github.com/sae-org/terraform-modules.git//modules/r53?ref=main"
  create_domain = false
  environment = "dev"
  region = "us-east-1"
  r53_records = module.acm.domain_records
}

