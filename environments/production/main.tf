terraform {
  required_version = ">= 1.6"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    # Configured via production.s3.tfbackend
  }
}

provider "cloudflare" {
  api_key = var.cloudflare_api_key
  email   = var.cloudflare_email
}

# ── Runner (CF Tunnel + DNS + Access for grafana/argocd/vm-push) ──

module "runner_tunnel" {
  source = "../../modules/cloudflare-tunnel"

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

# ── Portal (KV, D1, DNS, CF Access) ──

module "portal_edge" {
  source = "../../../cassandra-portal/infra/modules/portal-edge"

  account_id            = var.cloudflare_account_id
  zone_id               = var.zone_id
  domain                = var.domain
  subdomain             = "portal"
  worker_script_name    = "cassandra-portal"
  allowed_emails        = var.allowed_emails
  allowed_email_domains = var.allowed_email_domains
  google_idp_id         = var.google_idp_id
}

# ── YT-MCP (Tunnel + Worker edge + Backend Access) ──

module "yt_mcp_tunnel" {
  source = "../../modules/cloudflare-tunnel"

  account_id        = var.cloudflare_account_id
  zone_id           = var.zone_id
  domain            = var.domain
  subdomain         = "yt-mcp-api"
  tunnel_name       = "cassandra-yt-mcp"
  tunnel_secret     = var.tunnel_secret
  origin_url        = "http://localhost:3000"
  create_access_app = false
  skip_waf          = false
}

module "yt_mcp_worker_edge" {
  source = "../../../cassandra-yt-mcp/infra/modules/worker-edge"

  account_id         = var.cloudflare_account_id
  zone_id            = var.zone_id
  domain             = var.domain
  worker_script_name = "cassandra-yt-mcp"
  worker_subdomain   = "yt-mcp"
  enable_waf_skip    = false
}

module "yt_mcp_backend_access" {
  source = "../../../cassandra-yt-mcp/infra/modules/backend-access"

  account_id        = var.cloudflare_account_id
  zone_id           = var.zone_id
  domain            = var.domain
  backend_subdomain = "yt-mcp-api"
}

# ── Observability (CF Access service token for vm-push) ──

module "metrics_push" {
  source = "../../../cassandra-observability/infra/modules/metrics-push"

  account_id = var.cloudflare_account_id
  zone_id    = var.zone_id
  domain     = var.domain
}
