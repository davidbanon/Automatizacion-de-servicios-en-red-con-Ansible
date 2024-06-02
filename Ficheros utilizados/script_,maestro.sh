#!/bin/bash

# Función para imprimir una línea decorativa
print_line() {
    printf "%80s\n" | tr ' ' '='
}

# Función para imprimir un mensaje en una caja
print_message() {
    local message="$1"
    local len=${#message}
    local padding_left=$(( (80 - len) / 2 ))
    local padding_right=$(( 80 - len - padding_left ))
    printf "%${padding_left}s%s%${padding_right}s\n" "" "$message" ""
}

# Limpiar la pantalla
clear

# Imprimir el encabezado
print_line
print_message "¡AUTOMATIZACIÓN DE LA RED EN EJECUCIÓN!"
print_message "Por favor, deje esta ventana de terminal abierta o ejecútela en segundo plano."
print_message "Para detener el script, pulse CTRL+C."
print_message "Se puede ejecutar también en segundo plano con 'sudo nohup /script_maestro.sh &'"
print_line

# Obtener el ID del proceso del script
script_pid=$$

# Obtener el nombre de usuario actual
current_user=$SUDO_USER

# Si SUDO_USER está vacío, obtener el nombre de usuario actual usando whoami
if [ -z "$current_user" ]; then
    current_user=$(whoami)
fi

# Mostrar el comando para detener el script en segundo plano
echo "NOTA: Si se ejecuta el script en segundo plano, deberá detenerse con el siguiente comando: sudo kill $script_pid"
print_line
echo ""

# Ciclo principal
while true; do
    # Ejecutar el playbook y redirigir la salida estándar y la salida de error a un a>
    sudo -u "$current_user" ansible-playbook -i /hosts /playbook_maestro.yml

    # Mostrar el ID del proceso generado
    echo "PROCESO DEL SCRIPT ---> $script_pid"
    print_line

    # Copiar fichero macs en el resto de nodos
    sudo -u "$current_user" scp /macs_red.txt davidc@192.168.0.10:/macs_red.txt
    sudo -u "$current_user" scp /macs_red.txt davidc2@192.168.0.20:/macs_red.txt
    # Esperar 30s antes de la próxima ejecución
    sleep 30
done