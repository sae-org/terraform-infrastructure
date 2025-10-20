terraform {
  backend "s3" {
    bucket       = "sae-s3-terraform-backend"          
    key          = "dev/us-east-1/ec2/ansible/terraform.tfstate" 
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
  proj_prefix = "ansible-controller-dev"
  environment = "dev"
  region = "us-east-1"
  count = 1
  ins_type = "t2.micro"
  ami = "ami-020cba7c55df1f615"
  ec2_sg_id = [module.ansible_sg.sg_id]
  iam_ins_profile = "ansible-controller-dev-profile"
  associate_pub_ip = true
  user_data = file("${path.root}/user_data.sh")
  user_data_replace = true
}

module "ansible_sg" {
  source   = "git::https://github.com/sae-org/terraform-modules.git//modules/sg?ref=main"
  proj_prefix = "ansible-controller-dev"
  environment = "dev"
  region = "us-east-1"
  
  ingress_rules = [
    {
      from_port   = 22,
      to_port     = 22,
      protocol    = "tcp",
      cidr_blocks = ["0.0.0.0/0"]
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