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

variable "unifi_nodes" {
  description = "Map of node name → {mac, ip, note} for DHCP reservations"
  type = map(object({
    mac  = string
    ip   = string
    note = optional(string, "")
  }))
}
