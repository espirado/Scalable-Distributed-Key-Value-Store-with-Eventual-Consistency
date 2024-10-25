output "flow_log_id" {
  description = "The ID of the VPC Flow Log"
  value       = aws_flow_log.main.id
}

output "log_group_name" {
  description = "The name of the CloudWatch Log Group"
  value       = aws_cloudwatch_log_group.flow_logs.name
}

output "log_group_arn" {
  description = "The ARN of the CloudWatch Log Group"
  value       = aws_cloudwatch_log_group.flow_logs.arn
}