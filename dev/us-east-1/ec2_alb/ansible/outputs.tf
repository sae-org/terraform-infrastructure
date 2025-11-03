output "ec2" {
  value = module.ec2
  sensitive = true
}

output "sg" {
  value = module.ansible_sg
  sensitive = true
}
