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
  execution_role_arn   = data.terraform_remote_state.iam.outputs.iam.role_arn
  task_role_arn       = data.terraform_remote_state.iam.outputs.iam.role_arn
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
        StringLike   = { "token.actions.githubusercontent.com:sub" = "repo:sae-org/my-portfolio:ref:refs/heads/main" }
      }
    }]
  })

  # Inline policy kept in the SAME module call (your EC2 pattern)
  role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # --- ECR ---
      {
        Sid      = "EcrAuth",
        Effect   = "Allow",
        Action   = ["ecr:GetAuthorizationToken"],
        Resource = "*"
      },
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
        Resource = "arn:aws:ecr:${local.region}:${local.account_id}:repository/${local.ecr_repo}"
      },

      # --- ECS task def + service ops + tagging ---
      {
        Sid    = "EcsTaskDefOps",
        Effect = "Allow",
        Action = [
          "ecs:RegisterTaskDefinition",
          "ecs:DeregisterTaskDefinition",
          "ecs:DescribeTaskDefinition",
          "ecs:ListTaskDefinitions"
        ],
        Resource = "*"
      },
      {
        Sid    = "EcsServiceOps",
        Effect = "Allow",
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices",
          "ecs:ListServices",
          "ecs:DescribeClusters",
          "ecs:ListClusters"
        ],
        Resource = "*"
      },
      {
        Sid    = "EcsTagging",
        Effect = "Allow",
        Action = [
          "ecs:TagResource",
          "ecs:UntagResource",
          "ecs:ListTagsForResource"
        ],
        Resource = "*"
      }

      # --- ELBv2 describes (TG/LB lookups) ---
      {
        Sid    = "Elbv2Reads",
        Effect = "Allow",
        Action = [
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetGroupAttributes",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:DescribeTags"
        ],
        Resource = "*"
      },

      # --- EC2 describes (SG/VPC/Subnets) ---
      {
        Sid    = "Ec2Reads",
        Effect = "Allow",
        Action = [
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeRouteTables",
          "ec2:DescribeInternetGateways"
        ],
        Resource = "*"
      },

      # --- Pass task & execution roles ---
      {
        Sid      = "PassTaskRoles",
        Effect   = "Allow",
        Action   = "iam:PassRole",
        Resource = [
          local.execution_role_arn,
          local.task_role_arn
        ],
        Condition = {
          StringEquals = { "iam:PassedToService" = "ecs-tasks.amazonaws.com" }
        }
      },

      # --- Secrets Manager (your CI/CD secret) ---
      {
        Sid      = "ReadCICDSecret",
        Effect   = "Allow",
        Action   = ["secretsmanager:GetSecretValue","secretsmanager:DescribeSecret"],
        Resource = "arn:aws:secretsmanager:${local.region}:${local.account_id}:secret:cicd/my-portfolio-*"
      },

      # --- CloudWatch Logs ---
      # 1) read/list need Resource="*"
      {
        Sid    = "LogsReadListAll",
        Effect = "Allow",
        Action = [
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ],
        Resource = "*"
      },
      # 2) tag read for your specific group (correct action name)
      {
        Sid      = "LogsTagReadsForGroup",
        Effect   = "Allow",
        Action   = ["logs:ListTagsForResource"],
        Resource = "arn:aws:logs:${local.region}:${local.account_id}:log-group:/ecs/my-portfolio-dev"
      },
      # 3) manage your specific group
      {
        Sid      = "LogsManageMyGroup",
        Effect   = "Allow",
        Action   = ["logs:CreateLogGroup","logs:PutRetentionPolicy"],
        Resource = "arn:aws:logs:${local.region}:${local.account_id}:log-group:/ecs/my-portfolio-dev"
      },

      # --- Terraform backend + remote state prefixes ---
      # List bucket for your ECS state prefix
      {
        Sid      = "TerraformStateS3List",
        Effect   = "Allow",
        Action   = ["s3:ListBucket"],
        Resource = "arn:aws:s3:::sae-s3-terraform-backend",
        Condition = {
          StringLike = { "s3:prefix" = [
            "dev/us-east-1/ecs/my-portfolio/*",
            "dev/us-east-1/ecs/my-portfolio"
          ] }
        }
      },
      # R/W on ECS state objects
      {
        Sid      = "TerraformStateObjectsEcs",
        Effect   = "Allow",
        Action   = ["s3:GetObject","s3:PutObject","s3:DeleteObject"],
        Resource = "arn:aws:s3:::sae-s3-terraform-backend/dev/us-east-1/ecs/my-portfolio/*"
      },
      # List bucket for the remote states you READ
      {
        Sid      = "TFStateListVpcEcrIam",
        Effect   = "Allow",
        Action   = ["s3:ListBucket"],
        Resource = "arn:aws:s3:::sae-s3-terraform-backend",
        Condition = {
          StringLike = { "s3:prefix" = [
            "dev/us-east-1/vpc/*",
            "dev/us-east-1/vpc",
            "dev/us-east-1/ecr/my-portfolio/*",
            "dev/us-east-1/ecr/my-portfolio",
            "dev/us-east-1/iam/ecs-role/*",
            "dev/us-east-1/iam/ecs-role"
          ] }
        }
      },
      # Read-only on those remote state objects
      {
        Sid      = "TFStateObjectsVpcEcrIamReadOnly",
        Effect   = "Allow",
        Action   = ["s3:GetObject"],
        Resource = [
          "arn:aws:s3:::sae-s3-terraform-backend/dev/us-east-1/vpc/*",
          "arn:aws:s3:::sae-s3-terraform-backend/dev/us-east-1/ecr/my-portfolio/*",
          "arn:aws:s3:::sae-s3-terraform-backend/dev/us-east-1/iam/ecs-role/*"
        ]
      }

      # If you use a DynamoDB lock table for backend, add the DDB actions here.
    ]
  })
}
