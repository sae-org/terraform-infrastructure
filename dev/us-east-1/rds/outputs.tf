# RDS Outputs
output "rds" {
  description = "RDS instance details"
  value = {
    endpoint = module.rds.endpoint
    address  = module.rds.address
    port     = module.rds.port
    db_name  = module.rds.db_name
    username = module.rds.username
  }
  sensitive = true
}

# Password Outputs
output "db_password" {
  description = "Database master password"
  value       = random_password.db_password.result
  sensitive   = true
}

output "db_username" {
  description = "Database master username"
  value       = "saeeda"
}

# Secrets Manager Outputs
output "secret_arn" {
  description = "ARN of the secret in Secrets Manager"
  value       = module.db_secrets.secret_arn
}

# Security Group
output "rds_sg_id" {
  description = "RDS security group ID"
  value       = module.sg_rds.sg_id
}
