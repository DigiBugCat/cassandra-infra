output "vm_push_url" {
  description = "URL for metrics push — set as VM_PUSH_URL in Workers"
  value       = module.metrics_push.push_url
}

output "vm_push_client_id" {
  description = "CF Access client ID — set as VM_PUSH_CLIENT_ID in Workers"
  value       = module.metrics_push.client_id
}

output "vm_push_client_secret" {
  description = "CF Access client secret — set as VM_PUSH_CLIENT_SECRET in Workers"
  value       = module.metrics_push.client_secret
  sensitive   = true
}
