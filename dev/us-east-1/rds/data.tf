data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "sae-s3-terraform-backend"
    key    = "dev/us-east-1/vpc/terraform.tfstate"  
    region = "us-east-1"
  }
}

data "terraform_remote_state" "ecs" {
  backend = "s3"
  config = {
    bucket = "sae-s3-terraform-backend"
    key    = "dev/us-east-1/ecs/my-portfolio/terraform.tfstate"  
    region = "us-east-1"
  }
}