output "INSTANCE_PUBLIC_IP" {
  value       = aws_instance.instance.public_ip
  description = "IPv4 Public IP"
}

output "INSTANCE_ID" {
  value       = aws_instance.instance.id
  description = "Disambiguated ID"
}

output "INSTANCE_SSH_KEYPAIR" {
  value       = var.private_key_name
  description = "Name of used AWS SSH key "
}

output "INSTANCE_SSH_USER" {
  value       = var.aws_instance_username
  description = "Name of used AWS SSH key "
}