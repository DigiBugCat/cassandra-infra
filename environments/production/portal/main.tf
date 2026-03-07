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

module "portal" {
  source = "../../../modules/token-portal"

  account_id              = var.cloudflare_account_id
  zone_id                 = var.zone_id
  domain                  = "REDACTED_DOMAIN"
  subdomain               = "keys"
  worker_name             = "cassandra-portal"
  cf_api_token            = var.cf_api_token
  runner_access_app_id    = var.runner_access_app_id
  runner_access_policy_id = var.runner_access_policy_id
  allowed_emails          = var.allowed_emails
  google_idp_id           = "REDACTED_IDP_ID"
}
