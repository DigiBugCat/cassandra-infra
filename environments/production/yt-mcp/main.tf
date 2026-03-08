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

module "worker_edge" {
  source = "../../../../cassandra-yt-mcp/infra/modules/worker-edge"

  account_id         = var.cloudflare_account_id
  zone_id            = var.zone_id
  domain             = var.domain
  worker_script_name = "cassandra-yt-mcp"
  worker_subdomain   = var.worker_subdomain
  enable_waf_skip    = false
}

module "backend_access" {
  source = "../../../../cassandra-yt-mcp/infra/modules/backend-access"

  account_id        = var.cloudflare_account_id
  zone_id           = var.zone_id
  domain            = var.domain
  backend_subdomain = var.backend_subdomain
}
