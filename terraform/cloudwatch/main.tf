locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# Main Dashboard for KV Store
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${local.name_prefix}-main"

  dashboard_body = jsonencode({
    widgets = [
      # ALB Metrics
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix],
            [".", "TargetResponseTime", ".", "."],
            [".", "HTTPCode_Target_4XX_Count", ".", "."],
            [".", "HTTPCode_Target_5XX_Count", ".", "."]
          ]
          period = 300
          stat   = "Sum"
          region = data.aws_region.current.name
          title  = "ALB Metrics"
        }
      },

      # KV Store Node Metrics
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["KVStore", "WriteLatency", "ClusterName", var.cluster_name],
            [".", "ReadLatency", ".", "."],
            [".", "SuccessfulWrites", ".", "."],
            [".", "SuccessfulReads", ".", "."]
          ]
          period = 60
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "KV Store Performance"
        }
      },

      # Node Resource Utilization
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ContainerInsights", "node_cpu_utilization", "ClusterName", var.cluster_name],
            [".", "node_memory_utilization", ".", "."],
            [".", "node_network_total_bytes", ".", "."],
            [".", "node_filesystem_utilization", ".", "."]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "Node Resource Utilization"
        }
      },

      # Consistency Metrics
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["KVStore", "VersionConflicts", "ClusterName", var.cluster_name],
            [".", "ReplicationLag", ".", "."],
            [".", "QuorumSuccess", ".", "."],
            [".", "QuorumFailure", ".", "."]
          ]
          period = 60
          stat   = "Sum"
          region = data.aws_region.current.name
          title  = "Consistency Metrics"
        }
      }
    ]
  })
}

# Alarms for Critical Metrics
resource "aws_cloudwatch_metric_alarm" "high_error_rate" {
  alarm_name          = "${local.name_prefix}-high-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "High error rate detected"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  tags = {
    Name        = "${local.name_prefix}-high-error-rate"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_cloudwatch_metric_alarm" "high_latency" {
  alarm_name          = "${local.name_prefix}-high-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "High latency detected"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  tags = {
    Name        = "${local.name_prefix}-high-latency"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Log Metric Filters
resource "aws_cloudwatch_log_metric_filter" "error_logs" {
  name           = "${local.name_prefix}-error-logs"
  pattern        = "[timestamp, requestid, level = ERROR, message]"
  log_group_name = "/aws/kvstore/${var.environment}"

  metric_transformation {
    name      = "ErrorCount"
    namespace = "${var.project_name}/${var.environment}"
    value     = "1"
  }
}

data "aws_region" "current" {}