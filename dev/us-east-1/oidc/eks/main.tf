terraform {
  backend "s3" {
    bucket       = "sae-s3-terraform-backend"          
    key          = "dev/us-east-1/oidc/eks/terraform.tfstate" 
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

module "eks_oidc" {
  source   = "git::https://github.com/sae-org/terraform-modules.git//modules/oidc?ref=main"
  odic_url                    = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
  client_id_list              = ["sts.amazonaws.com"]
}