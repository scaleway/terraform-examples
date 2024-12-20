resource "scaleway_rdb_instance" "rdb01" {
  name              = "rdb_${var.app_name}"
  node_type         = "DB-PLAY2-PICO"
  engine            = "PostgreSQL-15"
  is_ha_cluster     = true
  disable_backup    = true
  user_name         = "tasks"
  password          = random_password.db.result
  volume_type       = "sbs_15k"
  volume_size_in_gb = 10
  private_network {
    pn_id       = scaleway_vpc_private_network.pn01.id
    enable_ipam = true
  }
}

resource "scaleway_rdb_database" "db01" {
  name        = "db_${var.app_name}"
  instance_id = scaleway_rdb_instance.rdb01.id
}

resource "scaleway_rdb_user" "usr01" {
  instance_id = scaleway_rdb_instance.rdb01.id
  name        = "usr_${var.app_name}"
  password    = random_password.usr.result
  is_admin    = true
}

resource "scaleway_rdb_privilege" "priv01" {
  instance_id   = scaleway_rdb_instance.rdb01.id
  user_name     = scaleway_rdb_user.usr01.name
  database_name = scaleway_rdb_database.db01.name
  permission    = "all"
}

resource "random_password" "db" {
  length      = 10
  min_numeric = 1
  min_upper   = 1
  min_lower   = 1
  min_special = 1
}

resource "random_password" "usr" {
  length      = 10
  min_numeric = 1
  min_upper   = 1
  min_lower   = 1
  min_special = 1
}
