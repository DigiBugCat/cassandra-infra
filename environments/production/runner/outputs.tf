output "tunnel_token" {
  description = "Tunnel token — seal this and add to cassandra-k8s values"
  value       = module.tunnel.tunnel_token
  sensitive   = true
}

output "hostname" {
  description = "Runner hostname"
  value       = module.tunnel.hostname
}
