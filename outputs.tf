output "backend_ip" {
  value = aws_instance.backend_instance.public_ip
  description = "IP pública del backend"
}

output "frontend_ip" {
  value = aws_instance.frontend_instance.public_ip
  description = "IP pública del frontend"
}

output "backend_url" {
  value = "http://${aws_instance.backend_instance.public_ip}:3001"
  description = "URL del backend"
}

output "frontend_url" {
  value = "http://${aws_instance.frontend_instance.public_ip}"
  description = "URL del frontend"
}