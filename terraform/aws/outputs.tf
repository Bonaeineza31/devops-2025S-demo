output "instance_public_ip" {
  description = "Public IP of the application instance"
  value       = aws_instance.app.public_ip
}

output "instance_private_ip" {
  description = "Private IP of the application instance"
  value       = aws_instance.app.private_ip
}

output "ssh_user" {
  description = "Default SSH user"
  value       = "ubuntu"
}

output "app_port" {
  description = "Port the application listens on"
  value       = 8000
}

output "db_public_ip" {
  description = "Public IP of the database instance"
  value       = aws_instance.db.public_ip
}

output "db_private_ip" {
  description = "Private IP of the database instance"
  value       = aws_instance.db.private_ip
}

output "db_ssh_port" {
  description = "SSH port of the database instance"
  value       = 22
}

