#!/usr/bin/env python3
import os

# Ruta al archivo de configuración DHCP
dhcpd_conf_path = "/etc/dhcp/dhcpd.conf"

# Ruta al archivo de MACs
macs_file_path = "/macs_red.txt"

# IP de inicio para reservas estáticas
start_ip = 100

# Lista de IPs a omitir
ips_to_omit = {"192.168.0.2", "192.168.0.10", "192.168.0.20"}

# Diccionario para almacenar las MACs reservadas y sus IPs asociadas
reserved_macs = {}

# Configuración inicial para el archivo dhcpd.conf
dhcpd_conf_initial = """
# Configuración básica de DHCP para la subred 192.168.0.0/24
default-lease-time 600;
max-lease-time 7200;
subnet 192.168.0.0 netmask 255.255.255.0 {
  # Rango de direcciones dinámicas
  range 192.168.0.21 192.168.0.99;
  option routers 192.168.0.1;
  option subnet-mask 255.255.255.0;
"""

# Leer el archivo dhcpd.conf existente para verificar MACs reservadas
if os.path.exists(dhcpd_conf_path):
    with open(dhcpd_conf_path, "r") as dhcpd_conf_file:
        for line in dhcpd_conf_file:
            if "hardware ethernet" in line and "fixed-address" in line:
                mac = line.split()[2].strip(';')
                ip = line.split()[1].strip(';').split('.')[-1]
                reserved_macs[mac] = ip

# Ajustar el contador de IPs para empezar desde start_ip y no repetir IPs
next_ip = start_ip

# Leer el archivo de MACs y generar configuraciones de host
hosts_config = ""
with open(macs_file_path, "r") as macs_file:
    for line in macs_file:
        mac, ip = line.strip().split()
        if ip in ips_to_omit:
            continue
        if mac in reserved_macs:
            continue
        reserved_macs[mac] = str(next_ip)
        reserved_ip = f"192.168.0.{next_ip}"
        host_config = f"""
  host {mac.replace(":", "")} {{
    hardware ethernet {mac};
    fixed-address {reserved_ip};
  }}
"""
        hosts_config += host_config
        next_ip += 1

# Configuración final para el archivo dhcpd.conf
dhcpd_conf_final = dhcpd_conf_initial + hosts_config + "}\n"

# Escribir la configuración final en el archivo dhcpd.conf
with open(dhcpd_conf_path, "w") as dhcpd_conf_file:
    dhcpd_conf_file.write(dhcpd_conf_final)

print(f"Archivo de configuración DHCP actualizado: {dhcpd_conf_path}")

# Reiniciar el servicio DHCP para aplicar los cambios (solo para sistemas basados en systemd)
os.system("sudo systemctl restart isc-dhcp-server")
