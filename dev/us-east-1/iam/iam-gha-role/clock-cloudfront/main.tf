terraform {
  backend "s3" {
    bucket       = "sae-s3-terraform-backend"
    key          = "dev/us-east-1/iam/iam-gha-role/clock-cloudfront/terraform.tfstate"
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

locals {
  region     = "us-east-1"
  account_id = data.aws_caller_identity.current.account_id
  ecr_repo = data.terraform_remote_state.ecr.outputs.ecr.ecr_repo_name
  execution_role_arn   = data.terraform_remote_state.iam.outputs.iam.role_arn
  task_role_arn       = data.terraform_remote_state.iam.outputs.iam.role_arn
}

module "iam_gha_clock_cloudfront" {
  source         = "git::https://github.com/sae-org/terraform-modules.git//modules/iam?ref=main"
  proj_prefix    = "gha-clock-cloudfront"
  create_profile = false

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRoleWithWebIdentity"
      Principal = { Federated = data.terraform_remote_state.oidc.outputs.oidc.oidc_arn }
      Condition = {
        StringEquals = { "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com" }
        StringLike   = { "token.actions.githubusercontent.com:sub" = "repo:sae-org/clock-cloudfront-cache:ref:refs/heads/main" }
      }
    }]
  })

  role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      # ECR auth token
      {
        Sid      = "EcrAuth",
        Effect   = "Allow",
        Action   = ["ecr:GetAuthorizationToken"],
        Resource = "*"
      },

      # ECR push/pull (scoped to your repo if you want)
      {
        Sid    = "EcrPushPull",
        Effect = "Allow",
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:PutImage",
          "ecr:BatchGetImage",
          "ecr:DescribeRepositories",
          "ecr:DescribeImages",
          "ecr:ListImages",
          "ecr:GetDownloadUrlForLayer"
        ],
        # scope to repo (uncomment next line) or keep "*" for simplicity:
        # Resource = "arn:aws:ecr:${local.region}:${local.account_id}:repository/${local.ecr_repo}"
        Resource = "*"
      },

      # ECS: register task definition + read it
      {
        Sid      = "EcsRegisterAndDescribeTaskDef",
        Effect   = "Allow",
        Action   = [
          "ecs:RegisterTaskDefinition",
          "ecs:DescribeTaskDefinition",
          "ecs:ListTaskDefinitions",
          "ecs:DeleteTaskDefinitions",
          "ecs:DeregisterTaskDefinition"
        ],
        Resource = "*"
      },

      # ECS: update/describe service (minimal)
      {
        Sid      = "EcsUpdateAndDescribeService",
        Effect   = "Allow",
        Action   = [
          "ecs:UpdateService",
          "ecs:DescribeServices",
          "ecs:ListClusters",
          "ecs:ListServices"
        ],
        Resource = "*"
      },

      # Pass the task execution & task roles to ECS tasks
      {
        Sid      = "PassTaskRoles",
        Effect   = "Allow",
        Action   = "iam:PassRole",
        Resource = [
          local.execution_role_arn,
          local.task_role_arn,
        ],
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "ecs-tasks.amazonaws.com"
          }
        }
      },

      # Read your consolidated Secrets Manager JSON
      {
        Sid      = "ReadCICDSecret",
        Effect   = "Allow",
        Action   = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Resource = "arn:aws:secretsmanager:${local.region}:${local.account_id}:secret:cicd/clock-cloudfront-*"
      }
    ]
  })
}


