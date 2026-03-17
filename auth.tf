# ── Auth Service (KV, DNS) ──

module "auth_worker" {
  source = "../cassandra-auth/infra/modules/auth-worker"

  account_id         = var.cloudflare_account_id
  zone_id            = var.zone_id
  domain             = var.domain
  worker_script_name = "cassandra-auth"
  worker_subdomain   = "auth"
}

output "auth_credentials_kv_namespace_id" {
  description = "KV namespace ID for per-user credentials"
  value       = module.auth_worker.credentials_kv_namespace_id
}

output "auth_url" {
  description = "Auth service base URL"
  value       = module.auth_worker.auth_url
}
