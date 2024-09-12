resource "unifi_network" "hvst-vlan-demo" {
  name    = var.harvester-new-vlan-name
  purpose = "vlan-only"

  subnet       = var.harvester-new-vlan-subnet-block
  vlan_id      = var.harvester-new-vlan
  dhcp_start   = var.harvester-new-vlan-network-dhcp-start
  dhcp_stop    = var.harvester-new-vlan-network-dhcp-end
  dhcp_enabled = true
}

resource "unifi_user" "hvstr-node-7-port2-eno2-embeddednic" {
  depends_on = [unifi_network.hvst-vlan-demo]
  mac        = "FC:15:B4:94:A9:23"
  name       = "hvstr-node7-prt2-eno2"
  note       = "harvester node 7 port 2 seen as eno2 will be mgmt-interface assigning static to enbedded nic port"
  fixed_ip   = "192.168.211.245"
  network_id = unifi_network.hvst-vlan-demo.id
}
