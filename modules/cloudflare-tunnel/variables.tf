variable "account_id" {
  description = "Cloudflare account ID"
  type        = string
}

variable "zone_id" {
  description = "Cloudflare zone ID"
  type        = string
}

variable "domain" {
  description = "Root domain (e.g. REDACTED_DOMAIN)"
  type        = string
}

variable "subdomain" {
  description = "Primary subdomain for the tunnel (e.g. runner)"
  type        = string
}

variable "tunnel_name" {
  description = "Name for the Cloudflare Tunnel"
  type        = string
}

variable "tunnel_secret" {
  description = "Base64-encoded tunnel secret (32+ random bytes)"
  type        = string
  sensitive   = true
}

variable "origin_url" {
  description = "URL of the primary origin service"
  type        = string
  default     = "http://localhost:8080"
}

variable "extra_ingress_rules" {
  description = "Additional ingress rules beyond the primary hostname"
  type = list(object({
    hostname      = string
    service       = string
    path          = optional(string)
    no_tls_verify = optional(bool, false)
  }))
  default = []
}

variable "extra_dns_hostnames" {
  description = "Additional hostnames that need DNS records pointing to this tunnel"
  type        = list(string)
  default     = []
}

variable "create_access_app" {
  description = "Whether to create a CF Access application for the primary subdomain"
  type        = bool
  default     = true
}

variable "skip_waf" {
  description = "Whether to create a WAF skip rule for the primary subdomain"
  type        = bool
  default     = true
}

variable "internal_hostnames" {
  description = "Hostnames to protect with CF Access (only reachable via service token)"
  type        = list(string)
  default     = []
}
