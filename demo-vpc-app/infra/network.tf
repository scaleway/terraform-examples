locals {
  subnet = "10.0.0.0/24"
}

resource "scaleway_vpc" "vpc01" {
  name = "vpc_${var.app_name}"
}

resource "scaleway_vpc_private_network" "pn01" {
  name   = "pn_${var.app_name}"
  vpc_id = scaleway_vpc.vpc01.id
  ipv4_subnet {
    subnet = local.subnet
  }
}

resource "scaleway_vpc_public_gateway_ip" "gwip01" {
}

resource "scaleway_vpc_public_gateway" "pgw01" {
  type            = "VPC-GW-S"
  name            = "pgw_${var.app_name}"
  ip_id           = scaleway_vpc_public_gateway_ip.gwip01.id
  bastion_enabled = true
  bastion_port    = 61000
}

resource "scaleway_ipam_ip" "vpcgw_ip" {
  address = cidrhost(local.subnet, 2)
  source {
    private_network_id = scaleway_vpc_private_network.pn01.id
  }
}

resource "scaleway_vpc_gateway_network" "gw01" {
  gateway_id         = scaleway_vpc_public_gateway.pgw01.id
  private_network_id = scaleway_vpc_private_network.pn01.id
  enable_masquerade  = true
  ipam_config {
    push_default_route = true
    ipam_ip_id         = scaleway_ipam_ip.vpcgw_ip.id
  }
}
