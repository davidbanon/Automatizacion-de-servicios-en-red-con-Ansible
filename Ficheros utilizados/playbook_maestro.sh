- name: Configuración de servicios y ejecución de scripts
  hosts: nodos
  tasks:
    - name: Apagar el servicio bind9 en todos los nodos
      raw: sudo systemctl stop bind9

    - name: Apagar el servicio isc-dhcp-server en todos los nodos
      raw: sudo systemctl stop isc-dhcp-server

- name: Ejecutar tareas en localhost
  hosts: localhost
  tasks:
    - name: Iniciar el servicio isc-dhcp-server en localhost
      raw: sudo systemctl start isc-dhcp-server

    - name: Iniciar el servicio bind9 en localhost
      raw: sudo systemctl start bind9

    - name: Ejecutar script nmap en localhost
      raw: sudo /script_nmap.sh
      register: output_nmap

    - name: Ejecutar script DHCP en localhost
      raw: sudo /script_dhcp.sh
      register: output_dhcp

    - name: Ejecutar script estático DNS en localhost
      raw: sudo /base_dns.sh
      register: output_static_dns

    - name: Ejecutar script dinámico DNS en localhost
      raw: sudo /script_dns.sh
      register: output_dynamic_dns

    - name: Imprimir salida del script nmap
      debug:
        var: output_nmap.stdout

    - name: Imprimir salida del script DHCP
      debug:
        var: output_dhcp.stdout

    - name: Imprimir salida del script estático DNS
      debug:
        var: output_static_dns.stdout

    - name: Imprimir salida del script dinámico DNS
      debug:
        var: output_dynamic_dns.stdout
