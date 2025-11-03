output "asg" {
  value = module.asg_clock_cloudfront
  sensitive = true
}

output "alb" {
  value = module.alb_clock_cloudfront
}