# ── Runner ──

output "runner_tunnel_token" {
  description = "Runner tunnel token — create as k8s secret"
  value       = module.runner_tunnel.tunnel_token
  sensitive   = true
}

output "runner_hostname" {
  description = "Runner hostname"
  value       = module.runner_tunnel.hostname
}

# ── Portal ──

output "portal_url" {
  value = module.portal_edge.portal_url
}

output "portal_mcp_keys_kv_id" {
  description = "KV namespace ID for MCP_KEYS — shared by portal + all MCP workers"
  value       = module.portal_edge.mcp_keys_kv_namespace_id
}

output "portal_db_id" {
  description = "D1 database ID for PORTAL_DB"
  value       = module.portal_edge.portal_db_id
}

# ── YT-MCP ──

output "yt_mcp_tunnel_token" {
  description = "YT-MCP backend tunnel token"
  value       = module.yt_mcp_tunnel.tunnel_token
  sensitive   = true
}

output "yt_mcp_backend_hostname" {
  value = module.yt_mcp_tunnel.hostname
}

output "yt_mcp_worker_hostname" {
  value = module.yt_mcp_worker_edge.worker_hostname
}

output "yt_mcp_mcp_url" {
  value = module.yt_mcp_worker_edge.mcp_url
}

output "yt_mcp_callback_url" {
  value = module.yt_mcp_worker_edge.callback_url
}

output "yt_mcp_oauth_kv_id" {
  description = "KV namespace ID for YT-MCP Worker OAuth state"
  value       = module.yt_mcp_worker_edge.kv_namespace_id
}

output "yt_mcp_access_client_id" {
  value = module.yt_mcp_backend_access.cf_access_client_id
}

output "yt_mcp_access_client_secret" {
  value     = module.yt_mcp_backend_access.cf_access_client_secret
  sensitive = true
}

# ── Observability ──

output "vm_push_url" {
  description = "URL for metrics push — set as VM_PUSH_URL in Workers"
  value       = module.metrics_push.push_url
}

output "vm_push_client_id" {
  value = module.metrics_push.client_id
}

output "vm_push_client_secret" {
  value     = module.metrics_push.client_secret
  sensitive = true
}
