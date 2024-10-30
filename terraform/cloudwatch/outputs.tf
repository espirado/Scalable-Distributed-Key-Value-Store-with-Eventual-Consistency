output "dashboard_name" {
  description = "Name of the main dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "dashboard_arn" {
  description = "ARN of the main dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_arn
}

output "alarm_arns" {
  description = "ARNs of the CloudWatch alarms"
  value = {
    high_error_rate = aws_cloudwatch_metric_alarm.high_error_rate.arn
    high_latency    = aws_cloudwatch_metric_alarm.high_latency.arn
  }
}