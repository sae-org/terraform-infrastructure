terraform {
  backend "s3" {
    bucket       = "sae-s3-terraform-backend"          
    key          = "dev/us-east-1/iam/iam-gha-role/my-portfolio/terraform.tfstate" 
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
  ecr_repo   = data.terraform_remote_state.ecr.outputs.ecr.ecr_repo_name
}

module "iam_gha_my_portfolio" {
  source         = "git::https://github.com/sae-org/terraform-modules.git//modules/iam?ref=main"
  proj_prefix    = "gha-my-portfolio"
  create_profile = false

  # OIDC trust (jsonencoded map; NO HCL blocks inside)
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRoleWithWebIdentity"
      Principal = { Federated = data.terraform_remote_state.oidc.outputs.oidc.oidc_arn }
      Condition = {
        StringEquals = { "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com" }
        StringLike   = { "token.actions.githubusercontent.com:sub" = "repo:sae-org/devops-portfolio:ref:refs/heads/main" }
      }
    }]
  })

  # Inline policy kept in the SAME module call (your EC2 pattern)
  role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # ECR auth
      {
        Effect: "Allow"
        Action: ["ecr:GetAuthorizationToken"]
        Resource: "*"
      },
      # Push/Pull for one repo
      {
        Effect: "Allow"
        Action: [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
          "ecr:BatchGetImage",
          "ecr:DescribeRepositories",
          "ecr:DescribeImages",
          "ecr:ListImages",
          "ecr:GetDownloadUrlForLayer"
        ]
        Resource: "arn:aws:ecr:${local.region}:${local.account_id}:repository/${local.ecr_repo}"
      },
      # Read just the needed secrets
      {
        Effect: "Allow"
        Action: ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
        Resource: [
          "arn:aws:secretsmanager:${local.region}:${local.account_id}:secret:ansible/ssh/controller-*",
          "arn:aws:secretsmanager:${local.region}:${local.account_id}:secret:ansible/controller_host-*",
          "arn:aws:secretsmanager:${local.region}:${local.account_id}:secret:ansible/controller_user-*"
        ]
      }
    ]
  })
}