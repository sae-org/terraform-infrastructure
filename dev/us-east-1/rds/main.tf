terraform {
  backend "s3" {
    bucket       = "sae-s3-terraform-backend"          
    key          = "dev/us-east-1/rds/my-portfolio/terraform.tfstate" 
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true                           
  }
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  profile = "tf"
}

# ============================================
# 1. Generate Random Password
# ============================================
resource "random_password" "db_password" {
  length  = 16
  special = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# ============================================
# 2. Store Password in Secrets Manager
# ============================================
module "db_secrets" {
  source        = "git::https://github.com/sae-org/terraform-modules.git//modules/secrets_manager?ref=main"
  secret_name   = "rds/my-portfolio-dev/master-password"
  secret_string = jsonencode({
    username = "saeeda"
    password = random_password.db_password.result
    engine   = "postgres"
    port     = 5432
    dbname   = "my_portfolio_dev_db"
  })
}

module "rds" {
  source   = "git::https://github.com/sae-org/terraform-modules.git//modules/rds?ref=main"
  proj_prefix = "my-portfolio-dev"
  subnet_ids = data.terraform_remote_state.vpc.outputs.vpc.pri_sub_id
  environment = "dev"
  engine = "postgres"
  engine_version = "15.3"
  instance_class = "db.t3.micro"
  allocated_storage = 20
  max_allocated_storage = 0
  storage_type = "gp2"
  storage_encrypted = true
  db_name = "my_portfolio_dev_db"
  username = "saeeda"
  password = random_password.db_password.result
  port = 5432
  vpc_security_group_ids = [module.sg_rds.sg_id]
  publicly_accessible = false
  backup_retention_period = 7
  backup_window = "00:00-03:00"
  skip_final_snapshot = true
  copy_tags_to_snapshot = true
  maintenance_window = "Mon:00:00-Mon:03:00"
  auto_minor_version_upgrade = true
  allow_major_version_upgrade = false
  apply_immediately = true
  multi_az = false
  deletion_protection = false
}

module "sg_rds" {                               
  source      = "git::https://github.com/sae-org/terraform-modules.git//modules/sg?ref=main"
  proj_prefix = "my-portfolio-rds"
  environment = "dev"
  region      = "us-east-1"
  
  ingress_rules = [
    {
      from_port       = 5432
      to_port         = 5432
      protocol        = "tcp"
      security_groups = [data.terraform_remote_state.ecs.outputs.ecs_svc_sg_id]  
    }
  ]

  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}