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

# DNS record for primary subdomain
resource "cloudflare_record" "tunnel" {
  zone_id = var.zone_id
  name    = var.subdomain
  content = "${cloudflare_zero_trust_tunnel_cloudflared.this.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

# DNS records for extra hostnames
resource "cloudflare_record" "extra" {
  for_each = toset(var.extra_dns_hostnames)

  zone_id = var.zone_id
  name    = each.value
  content = "${cloudflare_zero_trust_tunnel_cloudflared.this.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

# Tunnel config — route traffic to k8s services
resource "cloudflare_zero_trust_tunnel_cloudflared_config" "this" {
  account_id = var.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.this.id

  config {
    # Primary hostname ingress
    ingress_rule {
      hostname = "${var.subdomain}.${var.domain}"
      service  = var.origin_url
    }

    # Extra ingress rules
    dynamic "ingress_rule" {
      for_each = var.extra_ingress_rules
      content {
        hostname = ingress_rule.value.hostname
        service  = ingress_rule.value.service
        path     = ingress_rule.value.path

        dynamic "origin_request" {
          for_each = ingress_rule.value.no_tls_verify ? [1] : []
          content {
            no_tls_verify = true
          }
        }
      }
    }

    # Catch-all (required)
    ingress_rule {
      service = "http_status:404"
    }
  }
}

# WAF skip rule — bypass managed firewall rules for runner API traffic
resource "cloudflare_ruleset" "waf_skip" {
  count   = var.skip_waf ? 1 : 0
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

# --- CF Access: protect the primary subdomain with a service token ---

resource "cloudflare_zero_trust_access_application" "this" {
  count                      = var.create_access_app ? 1 : 0
  zone_id                    = var.zone_id
  name                       = var.tunnel_name
  domain                     = "${var.subdomain}.${var.domain}"
  type                       = "self_hosted"
  session_duration           = "24h"
  auto_redirect_to_identity  = false
  http_only_cookie_attribute = false
}

resource "cloudflare_zero_trust_access_service_token" "this" {
  count      = var.create_access_app ? 1 : 0
  account_id = var.account_id
  name       = "${var.tunnel_name}-service-token"
}

resource "cloudflare_zero_trust_access_policy" "service_token" {
  count          = var.create_access_app ? 1 : 0
  application_id = cloudflare_zero_trust_access_application.this[0].id
  zone_id        = var.zone_id
  name           = "Service token access"
  precedence     = 1
  decision       = "non_identity"

  include {
    service_token = [cloudflare_zero_trust_access_service_token.this[0].id]
  }
}

# --- CF Access: protect extra hostnames with Google OAuth ---

locals {
  access_hostnames = { for h in var.access_protected_hostnames : h.hostname => h }
}

resource "cloudflare_zero_trust_access_application" "extra" {
  for_each = local.access_hostnames

  zone_id                   = var.zone_id
  name                      = each.key
  domain                    = each.key
  type                      = "self_hosted"
  session_duration          = "24h"
  auto_redirect_to_identity = true
  allowed_idps              = [each.value.idp_id]
}

resource "cloudflare_zero_trust_access_policy" "extra" {
  for_each = local.access_hostnames

  application_id = cloudflare_zero_trust_access_application.extra[each.key].id
  zone_id        = var.zone_id
  name           = "Allowed Google users"
  precedence     = 1
  decision       = "allow"

  include {
    email        = each.value.emails
    email_domain = each.value.email_domains
  }
}
