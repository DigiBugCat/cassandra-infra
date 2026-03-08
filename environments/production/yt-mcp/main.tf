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

module "tunnel" {
  source = "../../../modules/cloudflare-tunnel"

  account_id        = var.cloudflare_account_id
  zone_id           = var.zone_id
  domain            = var.domain
  subdomain         = var.backend_subdomain
  tunnel_name       = "cassandra-yt-mcp"
  tunnel_secret     = var.tunnel_secret
  origin_url        = "http://localhost:3000"
  create_access_app = false
  skip_waf          = false
}

# TODO: Add worker-edge and backend-access modules when CF Worker frontend is built.
# These modules require CF provider v5 and the frontend redesign (WorkOS AuthKit gateway).
