#!/usr/bin/env python3

import os

ansible_hosts_file = "/var/lib/bind/ansible.hosts"
reverse_dns_file = "/var/lib/bind/db.192.168.0"
macs_red_file_path = "/macs_red.txt"

ips_to_omit = {"192.168.0.2", "192.168.0.10", "192.168.0.20"}

def get_ips_and_macs_from_macs_red():
    ip_mac_mapping = {}
    try:
        with open(macs_red_file_path, 'r') as f:
            for line in f:
                parts = line.strip().split()
                if len(parts) == 2:
                    mac, ip = parts
                    ip_mac_mapping[ip] = mac
    except Exception as e:
        print(f"Error al leer el archivo macs_red.txt: {e}")
    return ip_mac_mapping

def mac_exists_in_zone(mac, zone_file):
    try:
        with open(zone_file, 'r') as f:
            for line in f:
                if mac.replace(':', '') in line:
                    return True
    except Exception as e:
        print(f"Error al leer el archivo de zona: {e}")
    return False

def remove_mac_from_zone(mac, ip):
    try:
        mac_cleaned = mac.replace(':', '')
        ip_last_octet = ip.split('.')[-1]

        with open(ansible_hosts_file, 'r') as f:
            lines = f.readlines()
        with open(ansible_hosts_file, 'w') as f:
            for line in lines:
                if mac_cleaned not in line:
                    f.write(line)

        with open(reverse_dns_file, 'r') as f:
            lines = f.readlines()
        with open(reverse_dns_file, 'w') as f:
            for line in lines:
                if mac_cleaned not in line:
                    f.write(line)
    except Exception as e:
        print(f"Error al eliminar la MAC {mac} del archivo de zona: {e}")

def add_ip_to_zone(ip, mac):
    try:
        if ip in ips_to_omit:
            print(f"La IP {ip} está en la lista de IPs a omitir.")
            return

        if mac_exists_in_zone(mac, ansible_hosts_file):
            print(f"La MAC {mac} ya está en el archivo de zona directa. Actualizando la IP...")
            remove_mac_from_zone(mac, ip)

        with open(ansible_hosts_file, 'a') as f:
            f.write(f"{mac.replace(':', '')}.ansible.hosts.       IN      A       {ip}\n")

        reverse_octet = ip.split('.')[-1]
        with open(reverse_dns_file, 'a') as f:
            f.write(f"{reverse_octet}.0.168.192.in-addr.arpa.     IN      PTR     {mac.replace(':', '')}.ansible.hosts.\n")

        print(f"IP {ip} añadida a los archivos de zona con el nombre de cliente siendo la MAC.")

        with open(ansible_hosts_file, 'a') as f:
            f.write(f"{reverse_octet}.ansible.hosts.       IN      CNAME       {mac.replace(':', '')}.ansible.hosts.\n")

        print(f"CNAME {reverse_octet}.ansible.hosts. añadido en el archivo de zona.")
    except Exception as e:
        print(f"Error al agregar la IP {ip} a los archivos de zona: {e}")

ip_mac_mapping = get_ips_and_macs_from_macs_red()

for ip, mac in ip_mac_mapping.items():
    add_ip_to_zone(ip, mac)

# Reiniciar los servicios systemd-resolved y bind9
subprocess.run(["sudo", "systemctl", "restart", "systemd-resolved"])
subprocess.run(["sudo", "systemctl", "restart", "bind9"])

print("DNS actualizado correctamente.")