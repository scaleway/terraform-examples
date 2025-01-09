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
    cloud-init = <<-EOT
    #cloud-config

    runcmd:
      # Update and upgrade packages manually
      - apt-get update
      - apt-get -y upgrade

      # Install prerequisites for Docker + Python for URL-encoding
      - apt-get install -y apt-transport-https ca-certificates curl software-properties-common python3

      # Add Docker's GPG key and repository, then install Docker
      - curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
      - add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu jammy stable"
      - apt-get update
      - apt-get install -y docker.io
      - systemctl enable docker && systemctl start docker

      # URL-encode the password
      - DB_PASS=$(echo "${random_password.usr.result}" | python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read().strip(), safe=""))')

      # Write DSN environment variable and other configs
      - mkdir -p /opt/app
      - echo "DSN=postgres://${scaleway_rdb_user.usr01.name}:$DB_PASS@${scaleway_rdb_instance.rdb01.private_network.0.ip}:${scaleway_rdb_instance.rdb01.private_network.0.port}/${scaleway_rdb_database.db01.name}" > /opt/app/envfile

      # Pull and run the Docker image from Scaleway registry
      - docker pull ${scaleway_registry_namespace.ns01.endpoint}/app:latest
      - docker rm -f tasktracker || true
      - docker run -d --name tasktracker -p ${scaleway_lb_backend.bkd01.forward_port}:${scaleway_lb_backend.bkd01.forward_port} --env-file /opt/app/envfile ${scaleway_registry_namespace.ns01.endpoint}/app:latest
    EOT
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
