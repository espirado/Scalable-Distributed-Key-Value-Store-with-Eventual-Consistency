output "kvstore_lb_sg_id" {
  description = "ID of the Load Balancer security group"
  value       = aws_security_group.kvstore_lb.id
}

output "kvstore_nodes_sg_id" {
  description = "ID of the KV store nodes security group"
  value       = aws_security_group.kvstore_nodes.id
}

output "kvstore_monitoring_sg_id" {
  description = "ID of the monitoring security group"
  value       = aws_security_group.kvstore_monitoring.id
}