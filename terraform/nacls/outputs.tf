output "private_nacl_id" {
  description = "ID of the private subnets NACL"
  value       = aws_network_acl.private.id
}

output "public_nacl_id" {
  description = "ID of the public subnets NACL"
  value       = aws_network_acl.public.id
}