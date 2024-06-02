 #!/bin/bash

# Archivo para almacenar las direcciones MAC junto con las direcciones IP
macs_file="/macs_red.txt"

# Verificar si el archivo existe, si no, crearlo
if [ ! -f "$macs_file" ]; then
    touch "$macs_file"
fi

# Escaneo de la red para obtener las direcciones MAC e IP
nmap_output=$(sudo nmap -sn 192.168.0.0/24)


# Extraer las direcciones MAC y las direcciones IP asociadas y almacenarlas en el archivo
while read -r line; do
    mac=$(echo "$line" | awk '{print $1}')
    ip=$(echo "$line" | awk '{print $2}' | tr -d '()')

    # Comprobar si la dirección MAC ya está presente en el archivo
    if grep -q "$mac" "$macs_file"; then
        # Actualizar la dirección IP si es necesario
        sed -i "s/$mac.*/$mac $ip/" "$macs_file"
    else

        # Añadir la nueva dirección MAC e IP al archivo
        echo "$mac $ip" >> "$macs_file"
    fi
done < <(echo "$nmap_output" | awk '/Nmap scan report for/{ip=$NF}/MAC Address:/{print $3, ip}')
echo "Direcciones MAC junto con las direcciones IP guardadas en $macs_file"
