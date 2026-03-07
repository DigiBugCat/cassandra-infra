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
  description = "Base64-encoded tunnel secret for the portal tunnel"
  type        = string
  sensitive   = true
}

variable "allowed_emails" {
  description = "Emails allowed to access the portal"
  type        = list(string)
  default     = ["REDACTED_EMAIL"]
}

variable "google_idp_id" {
  description = "CF Access Google identity provider ID"
  type        = string
  default     = "REDACTED_IDP_ID"
}
