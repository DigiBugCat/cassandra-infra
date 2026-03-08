variable "account_id" {
  type = string
}

variable "zone_id" {
  type = string
}

variable "domain" {
  type = string
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
  description = "Runner orchestrator URL"
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

variable "allowed_email_domains" {
  description = "Email domains allowed to access the portal via Google OAuth (e.g. bluechipcapitalinvestments.com)"
  type        = list(string)
  default     = []
}

variable "google_idp_id" {
  description = "CF Access Google identity provider ID"
  type        = string
}
