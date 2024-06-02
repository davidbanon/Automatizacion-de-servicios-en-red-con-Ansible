#!/usr/bin/env python3

import os
import subprocess

def add_resolved_conf():
    resolved_conf = "/etc/systemd/resolved.conf"
    resolved_conf_backup = "/etc/systemd/resolved.conf.bak"
    dns_config = "DNS=192.168.0.2"
    resolve_section = "[Resolve]"

    # Lee el contenido del archivo actual
    with open(resolved_conf, "r") as file:
        lines = file.readlines()

    # Verifica si la configuración ya está presente
    if any(dns_config in line for line in lines):
        print("La configuración DNS ya está presente en /etc/systemd/resolved.conf")
        return

    # Realiza una copia de seguridad del archivo original si no existe
    if not os.path.exists(resolved_conf_backup):
        subprocess.run(["sudo", "cp", resolved_conf, resolved_conf_backup])

    # Añade las configuraciones si no están presentes
    with open(resolved_conf, "a") as file:
        if not any(resolve_section in line for line in lines):
            file.write(resolve_section + "\n")
        file.write(dns_config + "\n")

    # Reinicia systemd-resolved para aplicar los cambios
    subprocess.run(["sudo", "systemctl", "restart", "systemd-resolved"])

def create_direct_zone():
    hostname = os.getlogin()
    zone_file = f"/var/lib/bind/ansible.hosts"

    if not os.path.exists(zone_file):
        os.makedirs(os.path.dirname(zone_file), exist_ok=True)
        with open(zone_file, "w") as file:
            file.write(f"""$TTL    86400

ansible.hosts.       IN      SOA     {hostname}.ansible.hosts. admin.ansible. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
ansible.hosts.       IN      NS      {hostname}.ansible.hosts.

david.ansible.hosts.    IN      A       192.168.0.2
davidc.ansible.hosts.   IN      A       192.168.0.10
davidc2.ansible.hosts.  IN      A       192.168.0.20
""")

def create_reverse_zone():
    hostname = os.getlogin()
    reverse_zone_file = f"/var/lib/bind/db.192.168.0"

    if not os.path.exists(reverse_zone_file):
        os.makedirs(os.path.dirname(reverse_zone_file), exist_ok=True)
        with open(reverse_zone_file, "w") as file:
            file.write(f"""$TTL    86400

0.168.192.in-addr.arpa.       IN      SOA     {hostname}.ansible.hosts. admin.ansible. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;

0.168.192.in-addr.arpa.       IN      NS      {hostname}.ansible.hosts.

2.0.168.192.in-addr.arpa.     IN      PTR     david.ansible.hosts.
10.0.168.192.in-addr.arpa.    IN      PTR     davidc.ansible.hosts.
20.0.168.192.in-addr.arpa.    IN      PTR     davidc2.ansible.hosts.
""")

def update_named_conf_local():
    named_conf_local = "/etc/bind/named.conf.local"
    zone_direct = """
zone "ansible.hosts" {
    type master;
    file "/var/lib/bind/ansible.hosts";
};
"""
    zone_reverse = """
zone "0.168.192.in-addr.arpa" {
    type master;
    file "/var/lib/bind/db.192.168.0";
};
"""

    # Lee el contenido del archivo actual
    with open(named_conf_local, "r") as file:
        content = file.read()

    # Verifica si las configuraciones ya están presentes
    if 'zone "ansible.hosts"' in content and 'zone "0.168.192.in-addr.arpa"' in content:
        print("Las configuraciones de zona ya están presentes en /etc/bind/named.conf.local")
        return

    # Añade las configuraciones si no están presentes
    with open(named_conf_local, "a") as file:
        if 'zone "ansible.hosts"' not in content:
            file.write(zone_direct)
        if 'zone "0.168.192.in-addr.arpa"' not in content:
            file.write(zone_reverse)

    # Reinicia el servicio bind9 para aplicar los cambios
    subprocess.run(["sudo", "systemctl", "restart", "bind9"])
    subprocess.run(["sudo", "systemctl", "restart", "systemd-resolved"])

def main():
    add_resolved_conf()
    create_direct_zone()
    create_reverse_zone()
    update_named_conf_local()
    print(f"Script completado, las configuraciones DNS han sido actualizadas para el usuario {os.getlogin()}.")

if __name__ == "__main__":
    main()