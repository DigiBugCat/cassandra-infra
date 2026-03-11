# ── Single CF Tunnel — routes all k8s services through one cloudflared pod ──

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
    {
      hostname = "ci.${var.domain}"
      service  = "http://woodpecker-server.woodpecker.svc.cluster.local:80"
    },
    {
      hostname = "yt-mcp-api.${var.domain}"
      service  = "http://cassandra-yt-mcp.cassandra-yt-mcp.svc.cluster.local:3000"
    },
  ]

  extra_dns_hostnames = [
    "grafana",
    "argocd",
    "vm-push",
    "ci",
    "yt-mcp-api",
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
    {
      hostname      = "ci.${var.domain}"
      idp_id        = var.google_idp_id
      emails        = var.allowed_emails
      email_domains = var.allowed_email_domains
    },
  ]
}

# ── Woodpecker CI API — service token for CLI/API access through CF Access ──

resource "cloudflare_zero_trust_access_service_token" "woodpecker_ci" {
  account_id = var.cloudflare_account_id
  name       = "woodpecker-ci-api-token"
}

resource "cloudflare_zero_trust_access_policy" "woodpecker_ci_service_token" {
  application_id = module.runner_tunnel.extra_access_app_ids["ci.${var.domain}"]
  zone_id        = var.zone_id
  name           = "Woodpecker CI API service token"
  precedence     = 2
  decision       = "non_identity"

  include {
    service_token = [cloudflare_zero_trust_access_service_token.woodpecker_ci.id]
  }
}

output "woodpecker_ci_client_id" {
  description = "CF Access service token client ID for Woodpecker CI API"
  value       = cloudflare_zero_trust_access_service_token.woodpecker_ci.client_id
}

output "woodpecker_ci_client_secret" {
  description = "CF Access service token client secret for Woodpecker CI API"
  value       = cloudflare_zero_trust_access_service_token.woodpecker_ci.client_secret
  sensitive   = true
}

output "tunnel_token" {
  description = "Tunnel token — single tunnel for all k8s services"
  value       = module.runner_tunnel.tunnel_token
  sensitive   = true
}

output "runner_hostname" {
  description = "Runner hostname"
  value       = module.runner_tunnel.hostname
}
