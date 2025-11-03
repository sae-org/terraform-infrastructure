terraform {
  backend "s3" {
    bucket       = "sae-s3-terraform-backend"          
    key          = "dev/us-east-1/cloudfront/clock-cloudfront/terraform.tfstate" 
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

module "cloudfront" {
  source   = "git::https://github.com/sae-org/terraform-modules.git//modules/cloudfront?ref=main"
  proj_prefix = "clock-cloudfront"
  alb_dns_name = "origin.saeeda.me"
  cf_aliases = ["ecs-cdn-clock.saeeda.me"]
  cf_certificate_arn = data.terraform_remote_state.acm.outputs.acm.certificate_arns["*.saeeda.me"]
}

locals {
  origin_host = "origin.saeeda.me"
  cdn_host    = "ecs-cdn-clock.saeeda.me"
}

module "r53" {
  source   = "git::https://github.com/sae-org/terraform-modules.git//modules/r53?ref=main"
  create_domain = false
  environment = "dev"
  region = "us-east-1"
  r53_records = {
    "origin-a" = [{
      name  = local.origin_host
      type  = "A"
      alias = {
        name                   = data.terraform_remote_state.ecs_alb.outputs.alb.lb_dns
        zone_id                = data.terraform_remote_state.ecs_alb.outputs.alb.lb_zone
        evaluate_target_health = false
      }
    }]
    "cdn-a" = [{
      name  = local.cdn_host
      type  = "A"
      alias = {
        name                   = module.cloudfront.cloudfront_domain_name
        zone_id                = module.cloudfront.cloudfront_hosted_zone_id
        evaluate_target_health = false
      }
    }]
  }
}
