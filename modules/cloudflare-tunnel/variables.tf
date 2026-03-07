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
  description = "Subdomain for the tunnel (e.g. runner)"
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
  description = "URL of the origin service (e.g. http://localhost:8080)"
  type        = string
  default     = "http://localhost:8080"
}
