data "terraform_remote_state" "ecs" {
  backend = "s3"
  config = {
    bucket = "sae-s3-terraform-backend"
    key    = "dev/us-east-1/ecs/my-portfolio/terraform.tfstate" 
    region = "us-east-1"
  }
}

data "terraform_remote_state" "ecr" {
  backend = "s3"
  config = {
    bucket = "sae-s3-terraform-backend"
    key    = "dev/us-east-1/ecr/my-portfolio/terraform.tfstate" 
    region = "us-east-1"
  }
}

data "terraform_remote_state" "iam" {
  backend = "s3"
  config = {
    bucket = "sae-s3-terraform-backend"
    key    = "dev/us-east-1/iam/ecs-role/terraform.tfstate"
    region = "us-east-1"
  }
}