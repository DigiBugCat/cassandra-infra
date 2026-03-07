output "tunnel_token" {
  description = "Tunnel token — seal this and add to cassandra-k8s values"
  value       = module.tunnel.tunnel_token
  sensitive   = true
}

output "hostname" {
  description = "Runner hostname"
  value       = module.tunnel.hostname
}

output "cf_access_client_id" {
  description = "CF Access service token client ID — plugin sends as CF-Access-Client-Id header"
  value       = module.tunnel.cf_access_client_id
}

output "cf_access_client_secret" {
  description = "CF Access service token client secret — plugin sends as CF-Access-Client-Secret header"
  value       = module.tunnel.cf_access_client_secret
  sensitive   = true
}
