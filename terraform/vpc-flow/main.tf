locals {
  name_prefix = "${var.project}-${var.environment}"
}

# CloudWatch Log Group for VPC Flow Logs
resource "aws_cloudwatch_log_group" "flow_logs" {
  name              = "/aws/vpc-flow-logs/${local.name_prefix}"
  retention_in_days = var.retention_days

  tags = merge(
    var.tags,
    {
      Name        = "${local.name_prefix}-flow-logs"
      Environment = var.environment
      Project     = var.project
    }
  )
}

# IAM Role for VPC Flow Logs
resource "aws_iam_role" "flow_logs" {
  name = "${local.name_prefix}-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name        = "${local.name_prefix}-flow-logs-role"
      Environment = var.environment
      Project     = var.project
    }
  )
}

# IAM Policy for VPC Flow Logs
resource "aws_iam_role_policy" "flow_logs" {
  name = "${local.name_prefix}-flow-logs-policy"
  role = aws_iam_role.flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect = "Allow"
        Resource = [
          "${aws_cloudwatch_log_group.flow_logs.arn}",
          "${aws_cloudwatch_log_group.flow_logs.arn}:*"
        ]
      }
    ]
  })
}

# VPC Flow Log
resource "aws_flow_log" "main" {
  vpc_id                   = var.vpc_id
  traffic_type            = var.traffic_type
  iam_role_arn           = aws_iam_role.flow_logs.arn
  log_destination_type    = "cloud-watch-logs"
  log_destination        = aws_cloudwatch_log_group.flow_logs.arn
  max_aggregation_interval = 60

  tags = merge(
    var.tags,
    {
      Name        = "${local.name_prefix}-flow-log"
      Environment = var.environment
      Project     = var.project
    }
  )
}

# CloudWatch Metric Filter
resource "aws_cloudwatch_log_metric_filter" "rejected_traffic" {
  name           = "${local.name_prefix}-rejected-traffic"
  pattern        = "[version, account, eni, source, destination, srcport, destport, protocol, packets, bytes, windowstart, windowend, action=REJECT, flowlogstatus]"
  log_group_name = aws_cloudwatch_log_group.flow_logs.name

  metric_transformation {
    name          = "RejectedTrafficCount"
    namespace     = "${var.project}/${var.environment}/VPCFlowLogs"
    value         = "1"
    default_value = "0"
  }
}

# CloudWatch Alarm for Rejected Traffic
resource "aws_cloudwatch_metric_alarm" "rejected_traffic" {
  alarm_name          = "${local.name_prefix}-rejected-traffic"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "RejectedTrafficCount"
  namespace           = "${var.project}/${var.environment}/VPCFlowLogs"
  period              = "300"
  statistic           = "Sum"
  threshold           = "100"
  alarm_description   = "This metric monitors rejected VPC traffic"
  treat_missing_data  = "notBreaching"

  tags = merge(
    var.tags,
    {
      Name        = "${local.name_prefix}-rejected-traffic-alarm"
      Environment = var.environment
      Project     = var.project
    }
  )
}
