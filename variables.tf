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

variable "google_idp_id" {
  description = "CF Access Google identity provider ID"
  type        = string
}

# ── UniFi credentials ──

variable "unifi_username" {
  type      = string
  sensitive = true
}

variable "unifi_password" {
  type      = string
  sensitive = true
}

variable "unifi_api_url" {
  type = string
}

variable "unifi_network_name" {
  description = "Name of the UniFi network for DHCP reservations"
  type        = string
}

# ── UniFi node inventory ──

variable "unifi_nodes" {
  description = "Map of node name → {mac, ip, note} for DHCP reservations"
  type = map(object({
    mac  = string
    ip   = string
    note = optional(string, "")
  }))
}
