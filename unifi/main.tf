terraform {
  required_version = ">= 1.6"

  required_providers {
    unifi = {
      source  = "paultyng/unifi"
      version = "~> 0.41"
    }
  }

  backend "s3" {
    # Configured via backend.s3.tfbackend
  }
}

provider "unifi" {
  username       = var.unifi_username
  password       = var.unifi_password
  api_url        = var.unifi_api_url
  allow_insecure = true # self-signed cert on UDM
}

# ── UniFi: DHCP reservations for k3s cluster nodes ──

data "unifi_network" "default" {
  name = var.unifi_network_name
}

resource "unifi_user" "node" {
  for_each = var.unifi_nodes

  name       = each.key
  mac        = each.value.mac
  fixed_ip   = each.value.ip
  network_id = data.unifi_network.default.id
  note       = each.value.note
}
