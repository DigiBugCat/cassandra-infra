terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

# Worker script — serves portal UI + token management API
resource "cloudflare_workers_script" "portal" {
  account_id = var.account_id
  name       = var.worker_name
  content    = file("${path.module}/worker.js")
  module     = true

  secret_text_binding {
    name = "CF_API_TOKEN"
    text = var.cf_api_token
  }

  plain_text_binding {
    name = "CF_ACCOUNT_ID"
    text = var.account_id
  }

  plain_text_binding {
    name = "RUNNER_ACCESS_APP_ID"
    text = var.runner_access_app_id
  }

  plain_text_binding {
    name = "RUNNER_ACCESS_POLICY_ID"
    text = var.runner_access_policy_id
  }
}

# Custom domain route for the Worker
resource "cloudflare_workers_domain" "portal" {
  account_id = var.account_id
  hostname   = "${var.subdomain}.${var.domain}"
  service    = cloudflare_workers_script.portal.name
  zone_id    = var.zone_id
}

# CF Access application — protects the portal with Google OAuth
resource "cloudflare_zero_trust_access_application" "portal" {
  zone_id                    = var.zone_id
  name                       = "${var.worker_name}-portal"
  domain                     = "${var.subdomain}.${var.domain}"
  type                       = "self_hosted"
  session_duration           = "24h"
  auto_redirect_to_identity  = true
  allowed_idps               = [var.google_idp_id]
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
