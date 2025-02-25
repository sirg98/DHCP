#!/bin/bash

ayuda() {
    echo "=================================== AYUDA DEL SCRIPT DHCP ==================================="
    echo "Uso: $0 [OPCIÓN]"
    echo ""
    echo "--------------------------- Opciones disponibles: -------------------------------------------"
    echo "  activar                        - Iniciar el servicio DHCP"
    echo "  apagar                         - Detener el servicio DHCP"
    echo "  reiniciar                      - Reiniciar el servicio DHCP"
    echo "  estado                         - Mostrar estado del servicio DHCP"
    echo "  --logs recientes               - Mostrar logs de la última hora"
    echo "  --logs fecha YYYY-MM-DD        - Mostrar logs por fecha o rango de fechas"
    echo "  --logs tipo error|warning|info - Mostrar logs por tipo"
    echo "  --logs ultimos N               - Mostrar últimos N logs"
    echo "  instalar docker|ansible|apt    - Instalar servicio usando el método especificado"
    echo "  desinstalar docker|ansible|apt - Desinstalar servicio usando el método especificado"
    echo "  configurar DHCP                - edita el archivo dhcpd.conf"
    echo "  configurar netplan             - configura la interfaces de red del archivo netplan"
    echo "  Permisos Netplan               - da los permisos necesarios y guarda la config de netplan"
    echo "  ayuda                          - Mostrar esta ayuda"
    echo "  salir                          - Rompe el bucle y sale del menu"
    echo "  Sin argumentos ejecuta el menú interactivo"
    echo "=============================================================================================="
}

menu() {
    while true; do
    	echo "========== Información del sistema =========="
    	echo "Dirección IP: $(hostname -I)"
    	echo "Interfaz de red: $(ip -o -4 route show default | cut -d' ' -f5)"
    	echo "Estado del servicio DHCP: $(systemctl is-active isc-dhcp-server)"
    	echo "============================================="

        echo "========== Menú de Gestión DHCP ============="
        echo "1. Instalar servicio"
        echo "2. Desinstalar servicio"
        echo "3. Mostrar estado del servicio"
        echo "4. Arrancar servicio"
        echo "5. Detener servicio"
        echo "6. Reiniciar servicio"
        echo "7. Consultar logs"
        echo "8. Configurar DHCP"
        echo "9. Configurar Netplan"
        echo "10. Permisos NetPlan"
        echo "11. Ayuda"
        echo "12. Salir"
        echo "============================================"
        read -p "Selecciona una opción: " opcion

        case $opcion in
            1) seleccionar_instalacion_menu ;;
            2) seleccionar_desinstalacion_menu ;;
            3) gestionar_servicio estado ;;
            4) gestionar_servicio activar ;;
            5) gestionar_servicio apagar ;;
            6) gestionar_servicio reiniciar ;;
            7) consultar_logs_interactivo ;;
            8) configurar_dhcp ;;
            9) configurar_netplan ;;
            10) sudo chmod 644 /etc/netplan/*.yaml && echo "Permisos aplicados correctamente"  ;;
            11) ayuda ;;
            12) exit ;;
            *) echo "Opción inválida";;
        esac
    done
}

seleccionar_instalacion_menu() {
    echo "======================="
    echo "1. Instalar en docker"
    echo "2. Instalar en ansible"
    echo "3. Instalar en apt"
    echo "======================="
    read -p "Selecciona el método de instalación: " metodo
    case $metodo in
        1) instalar_docker ;;
        2) instalar_ansible ;;
        3) instalar_dhcp ;;
        *) echo "Opción inválida. Selecciona 1, 2 o 3." ;;
    esac
}

seleccionar_instalacion() {
    case $1 in
        docker) instalar_docker ;;
        ansible) instalar_ansible ;;
        apt) instalar_dhcp ;;
        "") seleccionar_instalacion_menu ;; 
        *) echo "Método inválido. Usa docker, ansible o apt." ;;
    esac
}

seleccionar_desinstalacion_menu() {
    echo "======================="
    echo "1. Desinstalar en docker"
    echo "2. Desinstalar en ansible"
    echo "3. Desinstalar en apt"
    echo "======================="
    read -p "Selecciona el método de desinstalación: " metodo
    
    case $metodo in
        1) desinstalar_docker ;;
        2) desinstalar_ansible ;;
        3) desinstalar_dhcp ;;
        *) echo "Opción inválida. Selecciona 1, 2 o 3." ;;
    esac
}

seleccionar_desinstalacion() {
    case $1 in
        docker) desinstalar_docker ;;
        ansible) desinstalar_ansible ;;
        apt) desinstalar_dhcp ;;
        "") seleccionar_desinstalacion_menu ;; # Si no hay parámetro, muestra el menu
        *) echo "Método inválido. Usa docker, ansible o apt." ;;
    esac
}

gestionar_servicio() {
    case $1 in
        activar) 
            echo "Iniciando el servicio DHCP..."
            sudo systemctl start isc-dhcp-server
            sleep 1  
            echo "Servicio DHCP iniciado."
            ;;
        apagar) 
            echo "Apagando el servicio DHCP..."
            sudo systemctl stop isc-dhcp-server
            sleep 1
            echo "Servicio DHCP detenido."
            ;;
        reiniciar) 
            echo "Reiniciando el servicio DHCP..."
            sudo systemctl restart isc-dhcp-server
            sleep 1
            echo "Servicio DHCP reiniciado."
            ;;
        estado) 
            echo "Estado actual del servicio DHCP:"
            systemctl status isc-dhcp-server --no-pager
            ;;
        *) 
            echo "Uso incorrecto: $0 {activar|apagar|reiniciar|estado}"
            ;;
    esac

    echo "Estado actual:"
    systemctl is-active isc-dhcp-server && echo "DHCP está activo." || echo "DHCP está inactivo."
}

consultar_logs_interactivo() {
    echo "======================="
    echo "Opciones de logs:"
    echo "1. Logs recientes (última hora)"
    echo "2. Logs por fecha"
    echo "3. Logs por tipo (error/warning/info)"
    echo "4. Últimos N logs"
    echo "======================="
    read -p "Selecciona una opción: " opcion_log

    case $opcion_log in
        1) 
            echo "Mostrando logs recientes del servicio DHCP..."
            journalctl -u isc-dhcp-server --since "1 hour ago"
            ;;
        2)
            read -p "Fecha inicio (YYYY-MM-DD): " fecha_inicio
            read -p "Fecha fin (YYYY-MM-DD) [opcional]: " fecha_fin
            if [ -z "$fecha_fin" ]; then
                echo "Mostrando logs desde $fecha_inicio..."
                journalctl -u isc-dhcp-server --since "$fecha_inicio 00:00:00"
            else
                echo "Mostrando logs entre $fecha_inicio y $fecha_fin..."
                journalctl -u isc-dhcp-server --since "$fecha_inicio 00:00:00" --until "$fecha_fin 23:59:59"
            fi
            ;;
        3)
            read -p "Tipo (error/warning/info): " tipo_log
            echo "Mostrando logs de tipo $tipo_log..."
            case $tipo_log in
                "error") tail -n 1000 /var/log/syslog | grep -i "dhcp" | grep -i "error" ;;
                "warning") tail -n 1000 /var/log/syslog | grep -i "dhcp" | grep -i "warning" ;;
                "info") tail -n 1000 /var/log/syslog | grep -i "dhcp" | grep -i "info" ;;
                *) echo "Tipo de log inválido. Use: error, warning o info" ;;
            esac
            ;;
        4)
            read -p "Número de logs a mostrar: " num_logs
            echo "Mostrando últimos $num_logs logs..."
            journalctl -u isc-dhcp-server -n "$num_logs"
            ;;
        *) echo "Opción inválida" ;;
    esac
}

consultar_logs() {
    case $1 in
        recientes)
            echo "Mostrando logs recientes..."
            journalctl -u isc-dhcp-server --since "1 hour ago"
            ;;
        fecha)
            shift
            if [ -z "$2" ]; then
                echo "Mostrando logs desde $1..."
                journalctl -u isc-dhcp-server --since "$1 00:00:00"
            else
                echo "Mostrando logs entre $1 y $2..."
                journalctl -u isc-dhcp-server --since "$1 00:00:00" --until "$2 23:59:59"
            fi
            ;;
        tipo)
            shift
            echo "Mostrando logs de tipo $1..."
            tail -n 1000 /var/log/syslog | grep -i "dhcp" | grep -i "$1"
            ;;
        ultimos)
            shift
            echo "Mostrando últimos $1 logs..."
            journalctl -u isc-dhcp-server -n "$1"
            ;;
        *)
            echo "Uso: $0 --logs {recientes 
            | fecha YYYY-MM-DD [YYYY-MM-DD] 
            | tipo error/warning/info 
            | ultimos N}"
            ;;
    esac
}

instalar_dhcp() {
    sudo apt update && sudo apt install isc-dhcp-server -y
    echo "Servicio DHCP instalado correctamente con APT."
}

instalar_ansible() {
    read -p "Ingrese la IP del servidor donde instalar DHCP: " SERVER_IP
    read -p "Ingrese el usuario SSH del servidor: " SERVER_USER
    sudo apt update && sudo apt install ansible -y
    echo "[dhcp_servers]" > hosts.ini
    echo "$SERVER_IP ansible_user=$SERVER_USER ansible_ssh_private_key_file=~/.ssh/id_rsa" >> hosts.ini
    ansible-playbook -i hosts.ini ./ansible-dhcp/install_dhcp.yml --ask-become-pass
    echo "Servicio DHCP instalado correctamente con Ansible."
}

instalar_docker() {
    
    sudo apt update && sudo apt install -y docker.io

    sudo systemctl start docker
    sudo systemctl enable docker

    if ! sudo systemctl is-active --quiet docker; then
        echo " Error: Docker no se está ejecutando. Verifica la instalación."
        exit 1
    fi
 
    sudo docker build -t dhcp-server ./docker-dhcp/
    
    if ! sudo docker images | grep -q "dhcp-server"; then
        echo "Error: La imagen dhcp-server no se creó correctamente."
        exit 1
    fi

    
    if sudo docker ps -a --format '{{.Names}}' | grep -q "^dhcp$"; then
        sudo docker stop dhcp
        sudo docker rm dhcp
    fi

    
    sudo docker run -d --name dhcp --dns=8.8.8.8 -p 6767:6767/udp dhcp-server

    
    if ! sudo docker ps --format '{{.Names}}' | grep -q "^dhcp$"; then
        echo "Error: El contenedor DHCP no se inició correctamente."
        exit 1
    fi

    echo "Servicio DHCP instalado correctamente con Docker."
}

desinstalar_dhcp() {
    sudo apt remove isc-dhcp-server -y
    sudo apt purge isc-dhcp-server -y
    echo "Servicio DHCP desinstalado."
}

desinstalar_ansible() {
    sudo apt remove --purge ansible -y
    sudo apt autoremove -y
    echo "Ansible ha sido desinstalado correctamente."
}

desinstalar_docker() {
    sudo docker stop dhcp
    sudo docker rm dhcp
    sudo docker rmi dhcp-server
    echo "Servicio DHCP en Docker ha sido eliminado"
}

configurar_dhcp() {
    read -p "Introduce la subred (ej: 192.168.1.0): " subred
    read -p "Introduce la máscara de subred (ej: 255.255.255.0): " mascara
    read -p "Introduce el rango inicial (ej: 192.168.1.100): " rango_inicio
    read -p "Introduce el rango final (ej: 192.168.1.200): " rango_fin
    read -p "Introduce la puerta de enlace (ej: 192.168.1.1): " puerta_enlace
    read -p "Introduce el servidor DNS (ej: 8.8.8.8,8.8.4.4): " dns

    sudo bash -c "cat > /etc/dhcp/dhcpd.conf" <<EOL
default-lease-time 600;
max-lease-time 7200;

subnet $subred netmask $mascara {
    range $rango_inicio $rango_fin;
    option routers $puerta_enlace;
    option domain-name-servers $dns;
}
EOL

    echo "Configuración actualizada. Reiniciando servicio..."
    sudo systemctl restart isc-dhcp-server
}

configurar_netplan() {
    
        read -p "Introduce el nombre de la interfaz (ej: enp0s3): " interfaz
        read -p "Introduce la dirección IP (ej: 192.168.1.10/24): " ip
        read -p "Introduce la puerta de enlace (ej: 192.168.1.1): " gateway
        read -p "Introduce los servidores DNS separados por comas (ej: 8.8.8.8,8.8.4.4): " dns

        sudo bash -c "cat > /etc/netplan/01-netcfg.yaml" <<EOL
network:
  version: 2
  ethernets:
    $interfaz:
      dhcp4: no
      addresses:
        - $ip
      gateway4: $gateway
      nameservers:
        addresses: [$dns]
EOL

        echo "Configuración de Netplan guardada. Aplicando cambios..."
        sudo netplan apply
        echo "Cambios aplicados correctamente."
    
}

# Verifica si hay argumentos
if [ $# -gt 0 ]; then
    case $1 in
        activar|apagar|reiniciar|estado)
            gestionar_servicio $1
            ;;
        --logs)
            shift
            consultar_logs $@
            ;;
        instalar)
            shift
            seleccionar_instalacion $1
            ;;
        desinstalar)
            shift
            seleccionar_desinstalacion $1
            ;;
        ayuda)
            ayuda
            ;;
        *)
            echo "Opción desconocida: $1"
            help
            ;;
    esac
else
    menu
fi
