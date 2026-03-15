# ── Cloudflare credentials ──

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

# ── Shared across services ──

variable "domain" {
  description = "Root domain"
  type        = string
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

variable "allowed_email_domains" {
  description = "Email domains allowed to access protected services via CF Access"
  type        = list(string)
  default     = []
}

variable "workos_authkit_domain" {
  description = "WorkOS AuthKit domain (e.g. your-slug.authkit.app)"
  type        = string
}

variable "workos_connect_client_id" {
  description = "WorkOS Connect OAuth Application client ID for CF Access"
  type        = string
}

variable "workos_connect_client_secret" {
  description = "WorkOS Connect OAuth Application client secret for CF Access"
  type        = string
  sensitive   = true
}
