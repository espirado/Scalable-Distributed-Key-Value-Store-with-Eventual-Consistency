output "public_zone_id" {
  description = "Public hosted zone ID"
  value       = aws_route53_zone.public.zone_id
}

output "private_zone_id" {
  description = "Private hosted zone ID"
  value       = var.create_private_zone ? aws_route53_zone.private[0].zone_id : null
}

output "public_nameservers" {
  description = "List of nameservers for the public zone"
  value       = aws_route53_zone.public.name_servers
}

output "api_endpoint" {
  description = "API endpoint URL"
  value       = "api.${local.subdomain}"
}

output "internal_api_endpoint" {
  description = "Internal API endpoint URL"
  value       = var.create_private_zone ? "api.${local.subdomain}.internal" : null
}