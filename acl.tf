# ── ACL Service (KV, DNS) ──

module "acl_edge" {
  source = "../cassandra-auth/infra/modules/acl-edge"

  account_id         = var.cloudflare_account_id
  zone_id            = var.zone_id
  domain             = var.domain
  worker_script_name = "cassandra-acl"
  worker_subdomain   = "acl"
}

output "acl_credentials_kv_namespace_id" {
  description = "KV namespace ID for per-user credentials"
  value       = module.acl_edge.credentials_kv_namespace_id
}

output "acl_url" {
  description = "ACL service base URL"
  value       = module.acl_edge.acl_url
}
