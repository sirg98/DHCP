#!/bin/bash

mostrar_info() {
    echo "========== Información del sistema =========="
    echo "🔹 Dirección IP: $(hostname -I)"
    echo "🔹 Interfaz de red: $(ip -o -4 route show default | awk '{print $5}')"
    echo "🔹 Estado del servicio DHCP: $(systemctl is-active isc-dhcp-server)"
    echo "============================================="
}

menu() {
    while true; do
        echo "========== Menú de Gestión DHCP =========="
        echo "1. Instalar servicio"
        echo "2. Desinstalar servicio"
        echo "3. Arrancar servicio"
        echo "4. Detener servicio"
        echo "5. Reiniciar servicio"
        echo "6. Consultar logs"
        echo "7. Configurar DHCP"
        echo "8. Configurar Netplan"
        echo "9. Editar configuración DHCP"
        echo "10. Salir"
        echo "=========================================="
        read -p "Selecciona una opción: " opcion

        case $opcion in
            1) seleccionar_instalacion ;;
            2) seleccionar_desinstalacion ;;
            3) gestionar_servicio start ;;
            4) gestionar_servicio stop ;;
            5) gestionar_servicio restart ;;
            6) consultar_logs_interactivo ;;
            7) configurar_dhcp ;;
            8) configurar_netplan ;;
            9) sudo nano /etc/dhcp/dhcpd.conf ;;
            10) exit ;;
            *) echo "Opción inválida";;
        esac
    done
}

seleccionar_instalacion() {
    echo "===== Selecciona el método de instalación ====="
    echo "1. Instalar con comandos (en la máquina)"
    echo "2. Instalar con Ansible"
    echo "3. Instalar con Docker"
    read -p "Elige una opción: " metodo

    case $metodo in
        1) instalar_dhcp ;;
        2) instalar_ansible ;;
        3) instalar_docker ;;
        *) echo "Opción inválida";;
    esac
}

seleccionar_desinstalacion() {
    echo "===== Selecciona el método de desinstalación ====="
    echo "1. Desinstalar servicio en la máquina"
    echo "2. Desinstalar Ansible"
    echo "3. Desinstalar Docker"
    read -p "Elige una opción: " metodo

    case $metodo in
        1) desinstalar_dhcp ;;
        2) desinstalar_ansible ;;
        3) desinstalar_docker ;;
        *) echo "Opción inválida";;
    esac
}

gestionar_servicio() {
    case $1 in
        start) sudo systemctl start isc-dhcp-server ;;
        stop) sudo systemctl stop isc-dhcp-server ;;
        restart) sudo systemctl restart isc-dhcp-server ;;
        status) systemctl status isc-dhcp-server ;;
        *) echo "Uso: $0 servicio {start|stop|restart|status}" ;;
    esac
}

consultar_logs_interactivo() {
    echo "===== Opciones de logs ====="
    echo "1. Ver logs recientes"
    echo "2. Buscar logs por fecha"
    echo "3. Buscar logs por tipo"
    echo "4. Ver los últimos N logs"
    read -p "Elige una opción: " log_opcion

    case $log_opcion in
        1) consultar_logs --recientes ;;
        2) 
            read -p "Introduce la fecha (YYYY-MM-DD): " fecha
            read -p "Introduce la fecha de fin (opcional, YYYY-MM-DD): " fecha_fin
            consultar_logs --fecha "$fecha" "$fecha_fin"
            ;;
        3) 
            read -p "Introduce el tipo de log (error, warning, info): " tipo
            consultar_logs --tipo "$tipo"
            ;;
        4)
            read -p "Introduce el número de líneas que quieres ver: " lineas
            consultar_logs --ultimos "$lineas"
            ;;
        *) echo "Opción inválida";;
    esac
}

consultar_logs() {
    case $1 in
        --recientes)
            journalctl -u isc-dhcp-server --since "1 hour ago"
            ;;
        --fecha)
            shift
            fecha=$1
            fecha_fin=$2
            if [ -z "$fecha_fin" ]; then
                journalctl -u isc-dhcp-server --since "$fecha 00:00:00"
            else
                journalctl -u isc-dhcp-server --since "$fecha 00:00:00" --until "$fecha_fin 23:59:59"
            fi
            ;;
        --tipo)
            shift
            tipo=$1
            journalctl -u isc-dhcp-server | grep -i "$tipo"
            ;;
        --ultimos)
            shift
            lineas=$1
            journalctl -u isc-dhcp-server -n "$lineas"
            ;;
        *)
            echo "Uso: $0 logs {--recientes | --fecha YYYY-MM-DD [YYYY-MM-DD] | --tipo error/warning/info | --ultimos N}"
            ;;
    esac
}

instalar_dhcp() {
    sudo apt update && sudo apt install isc-dhcp-server -y
    echo "Servicio DHCP instalado correctamente."
}

instalar_ansible() {
    sudo apt update && sudo apt install ansible -y
    ansible-playbook -i localhost, ./ansible-dhcp/install_dhcp.yml
}

instalar_docker() {
    sudo apt update && sudo apt install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker
    docker build -t dhcp-server .
    docker run -d --name dhcp -p 67:67/udp dhcp-server
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
    echo "Deteniendo y eliminando contenedor Docker..."
    sudo docker stop dhcp
    sudo docker rm dhcp
    echo "Eliminando imagen Docker..."
    sudo docker rmi dhcp-server
    echo "Desinstalando Docker..."
    sudo apt remove --purge -y docker.io
    sudo apt autoremove -y
    echo "Docker ha sido desinstalado correctamente."
}

configurar_dhcp() {
    echo "Configurando DHCP..."
    read -p "Introduce la subred: " subred
    read -p "Introduce la máscara de subred: " mascara
    read -p "Introduce el rango inicial: " rango_inicio
    read -p "Introduce el rango final: " rango_fin
    read -p "Introduce la puerta de enlace: " puerta_enlace
    read -p "Introduce el servidor DNS: " dns

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

mostrar_info

if [ $# -gt 0 ]; then
    case $1 in
        instalar_dhcp) instalar_dhcp ;;
        desinstalar_dhcp) desinstalar_dhcp ;;
        servicio) shift; gestionar_servicio "$@" ;;
        logs) shift; consultar_logs "$@" ;;
        configurar_dhcp) configurar_dhcp ;;
        *) echo "Uso: $0 {instalar_dhcp | desinstalar_dhcp | servicio start|stop|restart|status | logs --recientes|--fecha YYYY-MM-DD|--tipo error|--ultimos N | configurar_dhcp}" ;;
    esac
    exit 0
fi

menu
