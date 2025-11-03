data "terraform_remote_state" "ansible_ec2" {
  backend = "s3"
  config = {
    bucket = "sae-s3-terraform-backend"
    key    = "dev/us-east-1/ec2/ansible/terraform.tfstate" 
    region = "us-east-1"
  }
}
