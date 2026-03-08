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

variable "allowed_email_domains" {
  description = "Email domains allowed to access protected services via CF Access"
  type        = list(string)
  default     = []
}

variable "domain" {
  description = "Root domain"
  type        = string
}

variable "google_idp_id" {
  description = "CF Access Google identity provider ID"
  type        = string
}
