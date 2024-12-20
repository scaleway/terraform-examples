#!/usr/bin/env python3
import json
import sys
import os
from urllib.parse import quote_plus

TF_OUTPUTS_FILE = 'terraform_outputs.json'

def main():
    if not os.path.isfile(TF_OUTPUTS_FILE):
        print(f"Error: {TF_OUTPUTS_FILE} not found.", file=sys.stderr)
        sys.exit(1)

    with open(TF_OUTPUTS_FILE, 'r') as f:
        outputs = json.load(f)

    instance_ips      = outputs["instance_ips"]["value"]
    bastion_ip        = outputs["bastion_ip"]["value"]
    bastion_port      = outputs["bastion_port"]["value"]
    db_name           = outputs["db_name"]["value"]
    db_host           = outputs["db_host"]["value"]
    db_port           = outputs["db_port"]["value"]
    db_user           = outputs["db_user"]["value"]
    db_password       = outputs["db_password"]["value"]
    backend_port      = outputs["backend_port"]["value"]
    registry_endpoint = outputs["registry_endpoint"]["value"]
    app_image         = f"{registry_endpoint}/app:latest"

     # URL-encode the db_password
    db_password_encoded = quote_plus(db_password)

    # Print INI-style inventory with multiple hosts
    print("[app_servers]")
    for _, ip in instance_ips.items():
        print(
            f"{ip} "
            f"ansible_user=root "
            f"ansible_ssh_common_args=\"-o ProxyCommand='ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -W %h:%p bastion@{bastion_ip} -p {bastion_port}'\" "
            f"db_host={db_host} "
            f"db_port={db_port} "
            f"db_name={db_name} "
            f"db_user={db_user} "
            f"db_password=\"{db_password_encoded}\" "
            f"backend_port={backend_port} "
            f"app_image={app_image}"
        )

if __name__ == "__main__":
    main()
