output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.kvstore.dns_name
}

output "alb_arn" {
  description = "ARN of the load balancer"
  value       = aws_lb.kvstore.arn
}
output "alb_zone_id" {
  description = "The zone_id of the load balancer"
  value       = aws_lb.kvstore.zone_id
}
output "alb_arn_suffix" {
  description = "ARN suffix of the load balancer"
  value       = aws_lb.kvstore.arn_suffix
}



output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.kvstore.arn
}

output "http_listener_arn" {
  description = "ARN of the HTTP listener"
  value       = aws_lb_listener.http.arn
}

output "target_group_arn_suffix" {
  description = "ARN suffix of the target group"
  value       = aws_lb_target_group.kvstore.arn_suffix
}