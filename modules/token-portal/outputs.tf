output "portal_url" {
  description = "Portal URL"
  value       = "https://${var.subdomain}.${var.domain}"
}

output "worker_name" {
  description = "Deployed Worker name"
  value       = cloudflare_workers_script.portal.name
}
