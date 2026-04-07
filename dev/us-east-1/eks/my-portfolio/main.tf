terraform {
  backend "s3" {
    bucket       = "sae-s3-terraform-backend"          
    key          = "dev/us-east-1/eks/my-portfolio/terraform.tfstate" 
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true                           
  }
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
    }
    helm = {
      source  = "hashicorp/helm"
    }
  }
}

module "eks" {
  source   = "git::https://github.com/sae-org/terraform-modules.git//modules/eks?ref=main"
  proj_prefix = "my-portfolio"
  env         = "dev"
  kubernetes_version = "1.35"
  endpoint_public_access = true
  desired_size = 2
  max_size     = 3
  min_size     = 1
  argo_cd_app_name = "my-portfolio-argocd"
  argo_cd_app_repo_url = "https://github.com/sae-org/my-portfolio-helm.git"
  argo_cd_app_repo_target_revision = "main"
  argo_cd_app_repo_path = "my-portfolio-app"
}

# backend ------
# r53 ---------
# acm ---------
# vpc -------
# security groups in this module api server port access from my ip address 
# iam gha 
# oidc eks and gha 
# ecr


# argo cd deployed on cluster 
# create helm repo that holds all the manifests files