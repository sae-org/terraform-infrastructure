data "terraform_remote_state" "acm" {
  backend = "s3"
  config = {
    bucket = "sae-s3-terraform-backend"
    key    = "dev/us-east-1/acm/terraform.tfstate" 
    region = "us-east-1"
  }
}

data "terraform_remote_state" "ecs_alb" {
  backend = "s3"
  config = {
    bucket = "sae-s3-terraform-backend"
    key    = "dev/us-east-1/ecs/clock-cloudfront/terraform.tfstate"  
    region = "us-east-1"
  }
}