output "tunnel_token" {
  description = "Tunnel token for the backend cloudflared connector"
  value       = module.tunnel.tunnel_token
  sensitive   = true
}

output "backend_hostname" {
  description = "Backend hostname routed through Cloudflare Tunnel"
  value       = module.tunnel.hostname
}

output "worker_hostname" {
  description = "Public Worker hostname"
  value       = module.worker_edge.worker_hostname
}

output "mcp_url" {
  description = "Public MCP URL"
  value       = module.worker_edge.mcp_url
}

output "callback_url" {
  description = "WorkOS redirect URI"
  value       = module.worker_edge.callback_url
}

output "kv_namespace_id" {
  description = "KV namespace ID to bind in wrangler.jsonc"
  value       = module.worker_edge.kv_namespace_id
}

output "cf_access_client_id" {
  description = "CF Access service token client ID for Worker"
  value       = module.backend_access.cf_access_client_id
}

output "cf_access_client_secret" {
  description = "CF Access service token client secret for Worker"
  value       = module.backend_access.cf_access_client_secret
  sensitive   = true
}
