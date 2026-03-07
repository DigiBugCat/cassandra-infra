output "tunnel_token" {
  description = "Tunnel token — seal this and add to cassandra-k8s values"
  value       = module.tunnel.tunnel_token
  sensitive   = true
}

output "hostname" {
  description = "Runner hostname"
  value       = module.tunnel.hostname
}

output "internal_access_client_id" {
  description = "Service token client ID — add to portal .env"
  value       = module.tunnel.internal_access_client_id
}

output "internal_access_client_secret" {
  description = "Service token client secret — add to portal .env"
  value       = module.tunnel.internal_access_client_secret
  sensitive   = true
}
