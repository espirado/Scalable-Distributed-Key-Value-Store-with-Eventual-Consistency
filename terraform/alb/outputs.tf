output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.kvstore.dns_name
}

output "alb_arn" {
  description = "ARN of the load balancer"
  value       = aws_lb.kvstore.arn
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.kvstore.arn
}

output "http_listener_arn" {
  description = "ARN of the HTTP listener"
  value       = aws_lb_listener.http.arn
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener"
  value       = var.create_https_listener ? aws_lb_listener.https[0].arn : null
}
