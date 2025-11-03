terraform {
  backend "s3" {
    bucket       = "sae-s3-terraform-backend"          
    key          = "dev/us-east-1/sns/clock-cloudfront/terraform.tfstate" 
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

module "sns" {
  source   = "git::https://github.com/sae-org/terraform-modules.git//modules/sns?ref=main"
  proj_prefix = "clock-cloudfront"
  display_name = "clock-cloudfront-project-cw-sns"
  alert_email = "saeeda.devops@gmail.com"
}