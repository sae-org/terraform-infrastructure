terraform {
  backend "s3" {
    bucket       = "sae-s3-terraform-backend"          
    key          = "dev/us-east-1/secrets_manager/my-portfolio/terraform.tfstate" 
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

module "secrets" {
  source   = "git::https://github.com/sae-org/terraform-modules.git//modules/secrets_manager?ref=main"
  secret_name = "tf/aws/ssh_key_priv"
  secret_string = data.terraform_remote_state.ec2_my_portfolio.outputs.ec2[0].private_key_pem
}