terraform {
  backend "s3" {
    bucket       = "sae-s3-terraform-backend"          
    key          = "dev/us-east-1/ec2/my-portfolio/terraform.tfstate" 
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

module "ec2" {
  source   = "git::https://github.com/sae-org/terraform-modules.git//modules/ec2?ref=main"
  proj_prefix = "my-portfolio-dev"
  environment = "dev"
  region = "us-east-1"
  count = 1
  ins_type = "t2.micro"
  ami = "ami-020cba7c55df1f615"
  ec2_sg_id = [module.ec2_sg.sg_id]
  iam_ins_profile = "my-portfolio-dev-profile"
  associate_pub_ip = false
}

module "alb" {
  source   = "git::https://github.com/sae-org/terraform-modules.git//modules/lb?ref=main"
  proj_prefix = "my-portfolio-dev"
  environment = "dev"
  region = "us-east-1"
  internal = false 
  lb_type = "application" 
  security_groups = [module.sg_alb.sg_id]
  cert_name = "*.saeeda.me"
  ec2_id = module.ec2[0].instance_ids[0]
  listener_ports = [
    { port = 80, protocol = "HTTP" },
    { port = 443, protocol = "HTTPS" }
  ]
  tg_ports = [
    { port = 80, protocol = "HTTP" }
  ]
}
module "ec2_sg" {
  source   = "git::https://github.com/sae-org/terraform-modules.git//modules/sg?ref=main"
  proj_prefix = "my-portfolio-dev-ec2"
  environment = "dev"
  region = "us-east-1"
  
  ingress_rules = [
    {
      from_port   = 22,
      to_port     = 22,
      protocol    = "tcp",
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port       = 80,
      to_port         = 80,
      protocol        = "tcp",
      security_groups = [module.sg_alb.sg_id]
    },
    {
      from_port       = 443,
      to_port         = 443,
      protocol        = "tcp",
      security_groups = [module.sg_alb.sg_id]
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

module "sg_alb" {
  source = "git::https://github.com/sae-org/terraform-modules.git//modules/sg?ref=main"
  proj_prefix = "my-portfolio-dev-alb"
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
