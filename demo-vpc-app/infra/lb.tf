resource "scaleway_lb_ip" "ip01" {
}

resource "scaleway_ipam_ip" "lb_ip" {
  address = cidrhost(local.subnet, 10)
  source {
    private_network_id = scaleway_vpc_private_network.pn01.id
  }
}

resource "scaleway_lb" "lb01" {
  name   = "lb_${var.app_name}"
  ip_ids = [scaleway_lb_ip.ip01.id]
  type   = "LB-S"
  private_network {
    private_network_id = scaleway_vpc_private_network.pn01.id
    ipam_ids           = [scaleway_ipam_ip.lb_ip.id]
  }
}

resource "scaleway_lb_backend" "bkd01" {
  name             = "bkd_${var.app_name}"
  lb_id            = scaleway_lb.lb01.id
  forward_protocol = "http"
  forward_port     = 4000
  proxy_protocol   = "none"
  server_ips       = [for ip_res in values(scaleway_ipam_ip.instance_ips) : split("/", ip_res.address)[0]]

  health_check_port = 4000
  health_check_http {
    uri    = "/"
    code   = 200
    method = "GET"
  }
}

resource "scaleway_lb_frontend" "frt01" {
  name         = "frt_${var.app_name}"
  lb_id        = scaleway_lb.lb01.id
  backend_id   = scaleway_lb_backend.bkd01.id
  inbound_port = 80
}
