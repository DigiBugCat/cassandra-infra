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

# Portal tunnel — routes portal.REDACTED_DOMAIN to the portal nginx pod
module "tunnel" {
  source = "../../../modules/cloudflare-tunnel"

  account_id    = var.cloudflare_account_id
  zone_id       = var.zone_id
  domain        = "REDACTED_DOMAIN"
  subdomain     = "portal"
  tunnel_name   = "cassandra-portal"
  tunnel_secret = var.tunnel_secret
  origin_url    = "http://portal.portal.svc.cluster.local:80"

  # No service-token-based Access — portal uses Google OAuth (below)
  create_access_app = false
  skip_waf          = false
}

# CF Access application — protect portal with Google OAuth
resource "cloudflare_zero_trust_access_application" "portal" {
  zone_id                   = var.zone_id
  name                      = "cassandra-portal"
  domain                    = "portal.REDACTED_DOMAIN"
  type                      = "self_hosted"
  session_duration          = "24h"
  auto_redirect_to_identity = true
  allowed_idps              = [var.google_idp_id]
}

# Access policy — allow specific Google emails
resource "cloudflare_zero_trust_access_policy" "google_email" {
  application_id = cloudflare_zero_trust_access_application.portal.id
  zone_id        = var.zone_id
  name           = "Allowed Google users"
  precedence     = 1
  decision       = "allow"

  include {
    email = var.allowed_emails
  }
}
