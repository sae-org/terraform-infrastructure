terraform {
  backend "s3" {
    bucket       = "sae-s3-terraform-backend"          
    key          = "dev/us-east-1/cloudwatch/clock-cloudfront/terraform.tfstate" 
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
  source   = "git::https://github.com/sae-org/terraform-modules.git//modules/cloudwatch?ref=main"
  proj_prefix = "clock-cloudfront"
  asg_name = "clock-cloudfront-asg"
  sns_topic = data.terraform_remote_state.sns.outputs.sns.sns_topic_arn
}