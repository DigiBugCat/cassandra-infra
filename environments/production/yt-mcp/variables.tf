variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
}

variable "cloudflare_api_key" {
  description = "Cloudflare Global API Key"
  type        = string
  sensitive   = true
}

variable "cloudflare_email" {
  description = "Cloudflare account email"
  type        = string
}

variable "zone_id" {
  description = "Cloudflare zone ID"
  type        = string
}

variable "tunnel_secret" {
  description = "Base64-encoded tunnel secret"
  type        = string
  sensitive   = true
}

variable "domain" {
  description = "Service domain"
  type        = string
  default     = "REDACTED_DOMAIN"
}

variable "backend_subdomain" {
  description = "Backend subdomain exposed via CF tunnel"
  type        = string
  default     = "yt-mcp-api"
}

variable "worker_subdomain" {
  description = "Public MCP Worker subdomain"
  type        = string
  default     = "yt-mcp"
}
