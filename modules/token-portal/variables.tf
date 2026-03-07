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
  default = "keys"
}

variable "worker_name" {
  type    = string
  default = "cassandra-portal"
}

variable "cf_api_token" {
  description = "CF API token with Access read/write permissions (stored as Worker secret)"
  type        = string
  sensitive   = true
}

variable "runner_access_app_id" {
  description = "CF Access application ID for the runner (to manage policy)"
  type        = string
}

variable "runner_access_policy_id" {
  description = "CF Access policy ID on the runner app (to add/remove service tokens)"
  type        = string
}

variable "allowed_emails" {
  description = "Email addresses allowed to access the portal via Google OAuth"
  type        = list(string)
}
