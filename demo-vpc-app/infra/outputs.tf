output "app_url" {
  value = "http://${scaleway_lb.lb01.ip_address}"
}

output "connect_to_bastion" {
  value = "ssh -J bastion@${scaleway_vpc_public_gateway_ip.gwip01.address}:${scaleway_vpc_public_gateway.pgw01.bastion_port} root@${element(split("/", values(scaleway_ipam_ip.instance_ips)[0].address), 0)}"
}
