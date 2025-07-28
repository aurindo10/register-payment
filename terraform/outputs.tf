output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_eip.payment_eip.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.payment_server.public_dns
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ~/.ssh/payment-system-key ubuntu@${aws_eip.payment_eip.public_ip}"
}

output "api_endpoint" {
  description = "API endpoint URL"
  value       = "http://${aws_eip.payment_eip.public_ip}"
}

output "rabbitmq_management" {
  description = "RabbitMQ Management URL"
  value       = "http://${aws_eip.payment_eip.public_ip}:15672"
}

output "grafana_dashboard" {
  description = "Grafana Dashboard URL"
  value       = "http://${aws_eip.payment_eip.public_ip}:3000"
}

output "load_balancer_dns" {
  description = "Load balancer DNS name (if enabled)"
  value       = var.enable_load_balancer ? aws_lb.payment_alb[0].dns_name : null
} 