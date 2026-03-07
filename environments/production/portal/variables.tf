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
  default     = "https://claude-runner.REDACTED_DOMAIN"
}

variable "runner_admin_key" {
  description = "Admin API key for runner tenant management"
  type        = string
  sensitive   = true
}

variable "allowed_emails" {
  description = "Emails allowed to access the portal"
  type        = list(string)
  default     = ["REDACTED_EMAIL"]
}

variable "internal_access_client_id" {
  description = "CF Access service token client ID for internal proxy"
  type        = string
  default     = ""
}

variable "internal_access_client_secret" {
  description = "CF Access service token client secret for internal proxy"
  type        = string
  sensitive   = true
  default     = ""
}
