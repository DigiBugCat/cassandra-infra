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

module "metrics_push" {
  source = "github.com/DigiBugCat/cassandra-observability//infra/modules/metrics-push?ref=main"

  account_id = var.cloudflare_account_id
  zone_id    = var.zone_id
  domain     = var.domain
}
