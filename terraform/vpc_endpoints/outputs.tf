output "interface_endpoints" {
  description = "Map of interface endpoint IDs"
  value = {
    for k, v in aws_vpc_endpoint.interface_endpoints : k => v.id
  }
}

output "gateway_endpoints" {
  description = "Map of gateway endpoint IDs"
  value = {
    for k, v in aws_vpc_endpoint.gateway_endpoints : k => v.id
  }
}

output "vpc_endpoints_sg_id" {
  description = "VPC endpoints security group ID"
  value       = aws_security_group.vpc_endpoints.id
}