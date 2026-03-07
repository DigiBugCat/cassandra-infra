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

variable "cf_api_token" {
  description = "CF API token for Worker to manage service tokens"
  type        = string
  sensitive   = true
}

variable "runner_access_app_id" {
  description = "CF Access app ID for the runner"
  type        = string
  default     = "REDACTED_ACCESS_APP_ID"
}

variable "runner_access_policy_id" {
  description = "CF Access policy ID on the runner app"
  type        = string
  default     = "REDACTED_ACCESS_POLICY_ID"
}

variable "allowed_emails" {
  description = "Emails allowed to access the portal"
  type        = list(string)
  default     = ["REDACTED_EMAIL"]
}
