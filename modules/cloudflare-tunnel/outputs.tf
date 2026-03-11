output "tunnel_id" {
  description = "Cloudflare Tunnel ID"
  value       = cloudflare_zero_trust_tunnel_cloudflared.this.id
}

output "tunnel_token" {
  description = "Tunnel token for the cloudflared connector (use as k8s secret)"
  value       = cloudflare_zero_trust_tunnel_cloudflared.this.tunnel_token
  sensitive   = true
}

output "hostname" {
  description = "Full hostname for the tunnel"
  value       = "${var.subdomain}.${var.domain}"
}

output "cf_access_client_id" {
  description = "CF Access service token client ID (send as CF-Access-Client-Id header)"
  value       = var.create_access_app ? cloudflare_zero_trust_access_service_token.this[0].client_id : ""
}

output "cf_access_client_secret" {
  description = "CF Access service token client secret (send as CF-Access-Client-Secret header)"
  value       = var.create_access_app ? cloudflare_zero_trust_access_service_token.this[0].client_secret : ""
  sensitive   = true
}

output "access_app_id" {
  description = "CF Access application ID"
  value       = var.create_access_app ? cloudflare_zero_trust_access_application.this[0].id : ""
}

output "extra_access_app_ids" {
  description = "Map of hostname → CF Access application ID for extra protected hostnames"
  value       = { for k, v in cloudflare_zero_trust_access_application.extra : k => v.id }
}
