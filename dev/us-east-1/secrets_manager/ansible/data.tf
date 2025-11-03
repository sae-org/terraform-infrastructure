data "terraform_remote_state" "ec2_ansible" {
  backend = "s3"
  config = {
    bucket = "sae-s3-terraform-backend"
    key    = "dev/us-east-1/ec2/ansible/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "ec2_my_portfolio" {
  backend = "s3"
  config = {
    bucket = "sae-s3-terraform-backend"
    key    = "dev/us-east-1/ec2/my-portfolio/terraform.tfstate"
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

data "terraform_remote_state" "asg" {
  backend = "s3"
  config = {
    bucket = "sae-s3-terraform-backend"
    key    = "dev/us-east-1/asg/clock-cloudfront/terraform.tfstate"
    region = "us-east-1"
  }
}