variable "account_id" {
  type = string
}

variable "zone_id" {
  type = string
}

variable "domain" {
  type    = string
  default = "REDACTED_DOMAIN"
}

variable "subdomain" {
  type    = string
  default = "portal"
}

variable "worker_name" {
  type    = string
  default = "cassandra-portal"
}

variable "runner_url" {
  description = "Runner orchestrator URL (e.g. https://claude-runner.REDACTED_DOMAIN)"
  type        = string
}

variable "runner_admin_key" {
  description = "Admin API key for the runner's /tenants routes"
  type        = string
  sensitive   = true
}

variable "allowed_emails" {
  description = "Email addresses allowed to access the portal via Google OAuth"
  type        = list(string)
}

variable "google_idp_id" {
  description = "CF Access Google identity provider ID"
  type        = string
}

variable "internal_access_client_id" {
  description = "CF Access service token client ID for proxying to internal services"
  type        = string
  default     = ""
}

variable "internal_access_client_secret" {
  description = "CF Access service token client secret for proxying to internal services"
  type        = string
  sensitive   = true
  default     = ""
}
