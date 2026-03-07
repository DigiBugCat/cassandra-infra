output "tunnel_token" {
  description = "Tunnel token — seal and add to portal values-production.yaml"
  value       = module.tunnel.tunnel_token
  sensitive   = true
}

output "portal_url" {
  value = "https://portal.REDACTED_DOMAIN"
}
