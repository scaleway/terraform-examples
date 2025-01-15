resource "scaleway_instance_security_group" "sg01" {
  inbound_default_policy  = "drop"
  outbound_default_policy = "accept"

  inbound_rule {
    action   = "accept"
    port     = "22"
    ip_range = "${scaleway_vpc_public_gateway_ip.gwip01.address}/32"
  }

  inbound_rule {
    action   = "accept"
    port     = scaleway_lb_backend.bkd01.forward_port
    ip_range = "${split("/", scaleway_ipam_ip.lb_ip.address)[0]}/32"
  }
}

resource "scaleway_ipam_ip" "instance_ips" {
  for_each = toset([for i in range(var.instances_count) : tostring(i)])
  address  = cidrhost(local.subnet, 20 + each.value)
  source {
    private_network_id = scaleway_vpc_private_network.pn01.id
  }
}

resource "scaleway_instance_server" "srv01" {
  count             = var.instances_count
  name              = "server_${var.app_name}"
  image             = "ubuntu_jammy"
  type              = "PLAY2-PICO"
  security_group_id = scaleway_instance_security_group.sg01.id
  root_volume {
    volume_type = "sbs_volume"
    size_in_gb  = 50
    sbs_iops    = 15000
  }

  user_data = {
    cloud-init  = templatefile("${path.module}/cloud-init.yaml", {
    db_pass           = random_password.usr.result
    db_user           = scaleway_rdb_user.usr01.name
    db_host           = scaleway_rdb_instance.rdb01.private_network.0.ip
    db_port           = scaleway_rdb_instance.rdb01.private_network.0.port
    db_name           = scaleway_rdb_database.db01.name
    registry_endpoint = scaleway_registry_namespace.ns01.endpoint
    lb_port           = scaleway_lb_backend.bkd01.forward_port
    })
  }

  depends_on = [
    scaleway_rdb_privilege.priv01,
    scaleway_vpc_private_network.pn01,
    scaleway_vpc_public_gateway.pgw01
  ]
}

resource "scaleway_instance_private_nic" "pnic01" {
  count              = var.instances_count
  private_network_id = scaleway_vpc_private_network.pn01.id
  server_id          = scaleway_instance_server.srv01[count.index].id
  ipam_ip_ids        = [scaleway_ipam_ip.instance_ips[count.index].id]
}
