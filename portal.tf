# ── Portal (KV, D1, DNS, CF Access) ──

module "portal_edge" {
  source = "../cassandra-portal/infra/modules/portal-edge"

  account_id            = var.cloudflare_account_id
  zone_id               = var.zone_id
  domain                = var.domain
  subdomain             = "portal"
  worker_script_name    = "cassandra-portal"
  allowed_emails        = var.allowed_emails
  allowed_email_domains = var.allowed_email_domains
  idp_id                = cloudflare_zero_trust_access_identity_provider.workos.id
}

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
