output "tunnel_token" {
  description = "Tunnel token for the backend cloudflared connector"
  value       = module.tunnel.tunnel_token
  sensitive   = true
}

output "backend_hostname" {
  description = "Backend hostname routed through Cloudflare Tunnel"
  value       = module.tunnel.hostname
}

# TODO: Add worker_hostname, mcp_url, callback_url, kv_namespace_id,
# cf_access_client_id, cf_access_client_secret when CF Worker frontend is built.
