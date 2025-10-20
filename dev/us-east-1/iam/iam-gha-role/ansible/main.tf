terraform {
  backend "s3" {
    bucket       = "sae-s3-terraform-backend"          
    key          = "dev/us-east-1/iam/iam-gha-role/ansible/terraform.tfstate" 
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

data "aws_caller_identity" "current" {}

locals {
  region     = "us-east-1"
  account_id = data.aws_caller_identity.current.account_id
}

module "iam_gha_ansible_controller" {
  source         = "git::https://github.com/sae-org/terraform-modules.git//modules/iam?ref=main"
  proj_prefix    = "gha-ansible-controller"
  create_profile = false

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRoleWithWebIdentity"
      Principal = { Federated = data.terraform_remote_state.oidc.outputs.oidc.oidc_arn }
      Condition = {
        StringEquals = { "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com" }
        StringLike   = { "token.actions.githubusercontent.com:sub" = "repo:sae-org/ansible:ref:refs/heads/main" }
      }
    }]
  })

  role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadControllerSecrets"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          "arn:aws:secretsmanager:${local.region}:${local.account_id}:secret:ansible/controller/ssh_key_priv-*",
          "arn:aws:secretsmanager:${local.region}:${local.account_id}:secret:ansible/controller/host-*",
          "arn:aws:secretsmanager:${local.region}:${local.account_id}:secret:ansible/controller/user-*",
          "arn:aws:secretsmanager:${local.region}:${local.account_id}:secret:ansible/managed_hosts_ssh_keys/devops_portfolio-*",
          "arn:aws:secretsmanager:${local.region}:${local.account_id}:secret:ansible/controller/vault_file_secrets-*"
        ]
      }
    ]
  })

  policy_attachment = []
}
