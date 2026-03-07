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
