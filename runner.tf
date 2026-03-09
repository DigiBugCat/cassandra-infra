# ── Runner (CF Tunnel + DNS + Access for grafana/argocd/vm-push) ──

module "runner_tunnel" {
  source = "./modules/cloudflare-tunnel"

  account_id        = var.cloudflare_account_id
  zone_id           = var.zone_id
  domain            = var.domain
  subdomain         = "claude-runner"
  tunnel_name       = "cassandra-runner"
  tunnel_secret     = var.tunnel_secret
  origin_url        = "http://localhost:8080"
  create_access_app = false

  extra_ingress_rules = [
    {
      hostname = "grafana.${var.domain}"
      service  = "http://grafana.monitoring.svc.cluster.local:3000"
    },
    {
      hostname      = "argocd.${var.domain}"
      service       = "https://argocd-server.argocd.svc.cluster.local:443"
      no_tls_verify = true
    },
    {
      hostname = "vm-push.${var.domain}"
      service  = "http://vmsingle-vm-k8s-stack-victoria-metrics-k8s-stack.monitoring.svc:8428"
    },
  ]

  extra_dns_hostnames = [
    "grafana",
    "argocd",
    "vm-push",
  ]

  access_protected_hostnames = [
    {
      hostname      = "grafana.${var.domain}"
      idp_id        = var.google_idp_id
      emails        = var.allowed_emails
      email_domains = var.allowed_email_domains
    },
    {
      hostname      = "argocd.${var.domain}"
      idp_id        = var.google_idp_id
      emails        = var.allowed_emails
      email_domains = var.allowed_email_domains
    },
  ]
}

output "runner_tunnel_token" {
  description = "Runner tunnel token — create as k8s secret"
  value       = module.runner_tunnel.tunnel_token
  sensitive   = true
}

output "runner_hostname" {
  description = "Runner hostname"
  value       = module.runner_tunnel.hostname
}
