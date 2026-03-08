variable "cloudflare_api_key" {
  type      = string
  sensitive = true
}

variable "cloudflare_email" {
  type = string
}

variable "cloudflare_account_id" {
  type = string
}

variable "zone_id" {
  type = string
}

variable "tunnel_secret" {
  description = "Base64-encoded tunnel secret — generate with: openssl rand -base64 32"
  type        = string
  sensitive   = true
}

variable "allowed_emails" {
  description = "Email addresses allowed to access protected services via CF Access"
  type        = list(string)
}
