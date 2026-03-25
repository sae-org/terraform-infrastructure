output "ecs" {
  value = module.ecs
}

output "ecs_svc_sg_id" {
  description = "ECS service security group ID"
  value       = module.ecs_svc_sg.sg_id
}