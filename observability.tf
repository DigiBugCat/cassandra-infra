# ── Observability (CF Access service token for vm-push) ──

module "metrics_push" {
  source = "../cassandra-observability/infra/modules/metrics-push"

  account_id = var.cloudflare_account_id
  zone_id    = var.zone_id
  domain     = var.domain
}

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
