/*resource "scaleway_domain_zone" "dns_zone" {
  domain    = var.domain_name
  subdomain = var.subdomain_name
}


resource "scaleway_domain_record" "frontend_dns_record" {
  dns_zone = scaleway_domain_zone.dns_zone.id
  name     = var.frontend_dns_record_name
  type     = "A"
  data     = scaleway_lb_ip.lb_ip.ip_address
  ttl      = 3600
}

resource "scaleway_domain_record" "backend_dns_record" {
  dns_zone = scaleway_domain_zone.dns_zone.id
  name     = var.backend_dns_record_name
  type     = "A"
  data     = scaleway_lb_ip.lb_ip.ip_address
  ttl      = 3600

  depends_on = [
    scaleway_lb_ip.lb_ip
  ]
}*/