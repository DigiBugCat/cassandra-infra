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
