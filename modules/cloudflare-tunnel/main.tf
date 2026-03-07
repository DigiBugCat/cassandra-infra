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

# WAF skip rule — bypass managed firewall rules for runner API traffic
resource "cloudflare_ruleset" "waf_skip" {
  zone_id = var.zone_id
  name    = "Skip WAF for ${var.subdomain}"
  kind    = "zone"
  phase   = "http_request_firewall_custom"

  rules {
    action      = "skip"
    expression  = "(http.host eq \"${var.subdomain}.${var.domain}\")"
    description = "Skip firewall rules for runner API"
    action_parameters {
      ruleset = "current"
    }
    logging {
      enabled = true
    }
  }
}

# --- CF Access: protect the tunnel with a service token ---

# Access application — requires valid service token to reach the origin
resource "cloudflare_zero_trust_access_application" "this" {
  zone_id                   = var.zone_id
  name                      = var.tunnel_name
  domain                    = "${var.subdomain}.${var.domain}"
  type                      = "self_hosted"
  session_duration          = "24h"
  auto_redirect_to_identity = false

  # Allow WebSocket upgrades (needed for runner WS)
  http_only_cookie_attribute = false
}

# Service token — the plugin uses this to authenticate
resource "cloudflare_zero_trust_access_service_token" "this" {
  account_id = var.account_id
  name       = "${var.tunnel_name}-service-token"
}

# Access policy — allow the service token through
resource "cloudflare_zero_trust_access_policy" "service_token" {
  application_id = cloudflare_zero_trust_access_application.this.id
  zone_id        = var.zone_id
  name           = "Service token access"
  precedence     = 1
  decision       = "non_identity"

  include {
    service_token = [cloudflare_zero_trust_access_service_token.this.id]
  }
}
