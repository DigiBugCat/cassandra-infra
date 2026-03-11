# ── YT-MCP (Worker edge + Backend Access) ──
# Tunnel ingress for yt-mcp-api is handled by the single runner tunnel in runner.tf.

module "yt_mcp_worker_edge" {
  source = "../cassandra-yt-mcp/infra/modules/worker-edge"

  account_id         = var.cloudflare_account_id
  zone_id            = var.zone_id
  domain             = var.domain
  worker_script_name = "cassandra-yt-mcp"
  worker_subdomain   = "yt-mcp"
  enable_waf_skip    = false
}

module "yt_mcp_backend_access" {
  source = "../cassandra-yt-mcp/infra/modules/backend-access"

  account_id        = var.cloudflare_account_id
  zone_id           = var.zone_id
  domain            = var.domain
  backend_subdomain = "yt-mcp-api"
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
