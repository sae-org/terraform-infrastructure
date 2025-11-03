data "terraform_remote_state" "sns" {
  backend = "s3"
  config = {
    bucket = "sae-s3-terraform-backend"
    key    = "dev/us-east-1/sns/clock-cloudfront/terraform.tfstate" 
    region = "us-east-1"
  }
}

