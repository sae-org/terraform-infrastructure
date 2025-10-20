terraform {
  backend "s3" {
    bucket       = "sae-s3-terraform-backend"          
    key          = "dev/us-east-1/r53/terraform.tfstate" 
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

module "r53" {
  source   = "git::https://github.com/sae-org/terraform-modules.git//modules/r53?ref=main"
  create_domain = true 
  domain_name = "saeeda.me"
  environment = "dev"
  region = "us-east-1"
}
