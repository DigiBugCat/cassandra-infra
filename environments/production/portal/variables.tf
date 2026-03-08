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

variable "runner_url" {
  description = "Runner orchestrator URL"
  type        = string
}

variable "runner_admin_key" {
  description = "Admin API key for runner tenant management"
  type        = string
  sensitive   = true
}

variable "allowed_emails" {
  description = "Emails allowed to access the portal"
  type        = list(string)
}

variable "allowed_email_domains" {
  description = "Email domains allowed to access the portal"
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
