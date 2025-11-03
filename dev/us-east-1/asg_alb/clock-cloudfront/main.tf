terraform {
  backend "s3" {
    bucket       = "sae-s3-terraform-backend"          
    key          = "dev/us-east-1/asg/clock-cloudfront/terraform.tfstate" 
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

module "asg_clock_cloudfront" {
  source   = "git::https://github.com/sae-org/terraform-modules.git//modules/asg?ref=main"
  proj_prefix = "clock-cloudfront"
  ami = "ami-020cba7c55df1f615"
  environment = "dev"
  region = "us-east-1"
  ins_type = "t2.micro"
  asg_sg_id = module.asg_ins_sg.sg_id
  iam_ins_profile = "clock-cloudfront-profile"
  pub_ip = false
  tg_arns = module.alb_clock_cloudfront.tg_arns
  min_size = 2
  desired_capacity = 2
  max_size = 2
}

module "alb_clock_cloudfront" {
  source   = "git::https://github.com/sae-org/terraform-modules.git//modules/lb?ref=main"
  proj_prefix = "clock-cloudfront"
  environment = "dev"
  region = "us-east-1"
  internal = false 
  lb_type = "application" 
  security_groups = [module.asg_alb_sg.sg_id]
  cert_name = "*.saeeda.me"
  create_tg_attachment = false 
  listener_ports = [
    { port = 80, protocol = "HTTP" },
    { port = 443, protocol = "HTTPS" }
  ]
  tg_ports = [
    { port = 80, protocol = "HTTP" }
  ]
  target_port = 80
}
module "asg_ins_sg" {
  source   = "git::https://github.com/sae-org/terraform-modules.git//modules/sg?ref=main"
  proj_prefix = "clock-cloudfront-asg-ins"
  environment = "dev"
  region = "us-east-1"
  
  ingress_rules = [
    {
      from_port       = 80,
      to_port         = 80,
      protocol        = "tcp",
      security_groups = [module.asg_alb_sg.sg_id]
    }, 
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      security_groups = [data.terraform_remote_state.ansible_ec2.outputs.sg.sg_id] 
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

module "asg_alb_sg" {
  source = "git::https://github.com/sae-org/terraform-modules.git//modules/sg?ref=main"
  proj_prefix = "clock-cloudfront-asg-alb"
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
