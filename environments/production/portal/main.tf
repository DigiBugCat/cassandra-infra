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

module "portal_edge" {
  source = "github.com/DigiBugCat/cassandra-portal//infra/modules/portal-edge?ref=main"

  account_id            = var.cloudflare_account_id
  zone_id               = var.zone_id
  domain                = var.domain
  subdomain             = "portal"
  worker_script_name    = "cassandra-portal"
  allowed_emails        = var.allowed_emails
  allowed_email_domains = var.allowed_email_domains
  google_idp_id         = var.google_idp_id
}
