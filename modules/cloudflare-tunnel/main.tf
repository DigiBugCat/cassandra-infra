terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

# Cloudflare Tunnel — outbound-only connection from k8s to Cloudflare edge
resource "cloudflare_zero_trust_tunnel_cloudflared" "this" {
  account_id = var.account_id
  name       = var.tunnel_name
  secret     = var.tunnel_secret
}

# DNS record pointing subdomain to the tunnel
resource "cloudflare_record" "tunnel" {
  zone_id = var.zone_id
  name    = var.subdomain
  content = "${cloudflare_zero_trust_tunnel_cloudflared.this.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

# Tunnel config — route traffic to the k8s service
resource "cloudflare_zero_trust_tunnel_cloudflared_config" "this" {
  account_id = var.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.this.id

  config {
    ingress_rule {
      hostname = "${var.subdomain}.${var.domain}"
      service  = var.origin_url
    }
    # Catch-all (required)
    ingress_rule {
      service = "http_status:404"
    }
  }
}

# WAF skip rule — Cloudflare bot protection blocks Claude's User-Agent
resource "cloudflare_ruleset" "waf_skip" {
  zone_id = var.zone_id
  name    = "Skip bot protection for ${var.subdomain}"
  kind    = "zone"
  phase   = "http_request_sbfm"

  rules {
    action      = "skip"
    expression  = "(http.host eq \"${var.subdomain}.${var.domain}\")"
    description = "Skip bot fight mode for runner API"
    action_parameters {
      ruleset = "current"
    }
  }
}
