terraform {
  backend "s3" {
    bucket       = "sae-s3-terraform-backend"          
    key          = "dev/us-east-1/ecs/clock-cloudfront/terraform.tfstate" 
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

module "ecs" {
  source   = "git::https://github.com/sae-org/terraform-modules.git//modules/ecs?ref=main"
  proj_prefix = "clock-cloudfront-dev"
  execution_role_arn = data.terraform_remote_state.iam.outputs.iam.role_arn
  task_role_arn = data.terraform_remote_state.iam.outputs.iam.role_arn
  image_uri = "${data.terraform_remote_state.ecr.outputs.ecr.image_uri}:${var.image_tag}"
  app_port = 80
  env_vars = [
    { name = "APP_ENV",          value = "dev" },
    { name = "PORT",             value = "8080" },   # keep in sync with app_port
    { name = "AWS_REGION",       value = "us-east-1" },
    { name = "HEALTHCHECK_PATH", value = "/healthz" },
    { name = "LOG_LEVEL",        value = "info" }
  ]
  aws_region = "us-east-1"
  private_subnet_ids = data.terraform_remote_state.vpc.outputs.vpc.pri_sub_id
  svc_sg_id = module.ecs_svc_sg.sg_id
  tg_arn = module.alb.tg_arns[0]
  enable_container_insights = true
}

module "ecs_scaling" {
  source   = "git::https://github.com/sae-org/terraform-modules.git//modules/app_auto_scaling?ref=main"
  enabled = true 
  proj_prefix = "clock-cloudfront-dev"
  max_capacity = 4 
  min_capacity = 2
  cluster_name = module.ecs.cluster_name
  service_name = module.ecs.service_name
  enable_cpu = true
  cpu_target_percent = 50 
  scale_in_cooldown_seconds = 60
  scale_out_cooldown_seconds = 60 
  enable_memory = true 
  memory_target_percent = 60 
}
module "alb" {
  source   = "git::https://github.com/sae-org/terraform-modules.git//modules/lb?ref=main"
  proj_prefix = "clock-cloudfront-dev-ecs"
  create_tg_attachment = false
  environment = "dev"
  region = "us-east-1"
  internal = false 
  lb_type = "application" 
  target_type = "ip"
  security_groups = [module.ecs_alb_sg.sg_id]
  cert_name = "*.saeeda.me"
  listener_ports = [
    { port = 80, protocol = "HTTP" },
    { port = 443, protocol = "HTTPS" }
  ]
  tg_ports = [
    { port = 80, protocol = "HTTP" }
  ]
  target_port = 80
}

module "ecs_alb_sg" {
  source   = "git::https://github.com/sae-org/terraform-modules.git//modules/sg?ref=main"
  proj_prefix = "clock-cloudfront-ecs-alb"
  environment = "dev"
  region = "us-east-1"
  
  ingress_rules = [
    {
      from_port   = 80,
      to_port     = 80,
      protocol    = "tcp",
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port   = 443,
      to_port     = 443,
      protocol    = "tcp",
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  egress_rules = [
    {
      from_port   = 0,
      to_port     = 0,
      protocol    = "-1",
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

module "ecs_svc_sg" {
  source   = "git::https://github.com/sae-org/terraform-modules.git//modules/sg?ref=main"
  proj_prefix = "clock-cloudfront-ecs-svc"
  environment = "dev"
  region = "us-east-1"

  ingress_rules = [
    {
      from_port       = 80,
      to_port         = 80,
      protocol        = "tcp",
      security_groups = [module.ecs_alb_sg.sg_id]
    }, 
  ]

  egress_rules = [
    {
      from_port   = 0,
      to_port     = 0,
      protocol    = "-1",
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

