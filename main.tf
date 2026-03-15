terraform {
  required_version = ">= 1.6"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    # Configured via environments/production/production.s3.tfbackend
  }
}

provider "cloudflare" {
  api_key = var.cloudflare_api_key
  email   = var.cloudflare_email
}

# ── WorkOS OIDC Identity Provider (shared by all CF Access apps) ──

resource "cloudflare_zero_trust_access_identity_provider" "workos" {
  account_id = var.cloudflare_account_id
  name       = "WorkOS"
  type       = "oidc"

  config {
    client_id     = var.workos_connect_client_id
    client_secret = var.workos_connect_client_secret
    auth_url      = "https://${var.workos_authkit_domain}/oauth2/authorize"
    token_url     = "https://${var.workos_authkit_domain}/oauth2/token"
    certs_url     = "https://${var.workos_authkit_domain}/oauth2/jwks"
    scopes        = ["openid", "profile", "email"]
  }
}

