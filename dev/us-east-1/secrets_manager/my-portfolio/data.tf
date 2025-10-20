data "terraform_remote_state" "ec2_my_portfolio" {
  backend = "s3"
  config = {
    bucket = "sae-s3-terraform-backend"
    key    = "dev/us-east-1/ec2/my-portfolio/terraform.tfstate"
    region = "us-east-1"
  }
}