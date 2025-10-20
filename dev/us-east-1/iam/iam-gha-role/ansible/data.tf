data "terraform_remote_state" "oidc" {
  backend = "s3"
  config = {
    bucket = "sae-s3-terraform-backend"
    key    = "dev/us-east-1/oidc/gha/terraform.tfstate"
    region = "us-east-1"
  }
}