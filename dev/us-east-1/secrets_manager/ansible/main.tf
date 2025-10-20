terraform {
  backend "s3" {
    bucket       = "sae-s3-terraform-backend"
    key          = "dev/us-east-1/secrets_manager/ansible/terraform.tfstate"
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
    "ansible/controller/ssh_key_priv"             = data.terraform_remote_state.ec2_ansible.outputs.ec2[0].private_key_pem
    "ansible/controller/host"                     = data.terraform_remote_state.ec2_ansible.outputs.ec2[0].public_ip[0]
    "ansible/controller/user"                     = "ubuntu"
    "ansible/managed_hosts_ssh_keys/my_portfolio" = data.terraform_remote_state.ec2_my_portfolio.outputs.ec2[0].private_key_pem
  }
}

module "ansible_secrets" {
  source        = "git::https://github.com/sae-org/terraform-modules.git//modules/secrets_manager?ref=main"
  for_each      = local.secrets_map
  secret_name   = each.key
  secret_string = tostring(each.value)
}