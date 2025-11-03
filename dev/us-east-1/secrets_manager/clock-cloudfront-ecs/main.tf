terraform {
  backend "s3" {
    bucket       = "sae-s3-terraform-backend"
    key          = "dev/us-east-1/secrets_manager/clock-cloudfront/terraform.tfstate"
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
  region  = "us-east-1"
  profile = "tf"
}

data "aws_caller_identity" "current" {}

# Building a name→value map for all the secrets want to write 
locals {
  secrets_map = {
    "ECR_REPO_URL" = data.terraform_remote_state.ecr.outputs.ecr.repo_url
    "ECS_CLUSTER_NAME" = data.terraform_remote_state.ecs.outputs.ecs.cluster_name
    "ECS_SERVICE_NAME" = data.terraform_remote_state.ecs.outputs.ecs.service_name
    "ECS_TASK_FAMILY" = "clock-cloudfront-dev"
    "ECS_CONTAINER_NAME" =  "clock-cloudfront-dev"
    "TASK_CPU" = "256"
    "TASK_MEMORY" = "512"
    "LOG_GROUP" = "/ecs/clock-cloudfront-dev"
    "APP_PORT" = "80"
    "EXECUTION_ROLE_ARN" = data.terraform_remote_state.iam.outputs.iam.role_arn
    "TASK_ROLE_ARN" = data.terraform_remote_state.iam.outputs.iam.role_arn
  }
}

module "secrets" {
  source        = "git::https://github.com/sae-org/terraform-modules.git//modules/secrets_manager?ref=main"
  secret_name   = "cicd/clock-cloudfront"
  secret_string = jsonencode(local.secrets_map)
}