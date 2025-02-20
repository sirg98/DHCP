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
    read -p "Selecciona el método de instalación (docker, ansible, apt): " metodo
    case $metodo in
        docker) instalar_docker ;;
        ansible) instalar_ansible ;;
        apt) instalar_dhcp ;;
        *) echo "Opción inválida. Usa docker, ansible o apt." ;;
    esac
}

seleccionar_desinstalacion() {
    read -p "Selecciona el método de desinstalación (docker, ansible, apt): " metodo
    case $metodo in
        docker) desinstalar_docker ;;
        ansible) desinstalar_ansible ;;
        apt) desinstalar_dhcp ;;
        *) echo "Opción inválida. Usa docker, ansible o apt." ;;
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

consultar_logs() {
    case $1 in
        --recientes) journalctl -u isc-dhcp-server --since "1 hour ago" ;;
        --fecha) shift; journalctl -u isc-dhcp-server --since "$1 00:00:00" --until "$2 23:59:59" ;;
        --tipo) shift; journalctl -u isc-dhcp-server | grep -i "$1" ;;
        --ultimos) shift; journalctl -u isc-dhcp-server -n "$1" ;;
        *) echo "Uso: $0 logs {--recientes | --fecha DD-MM-YYYY [DD-MM-YYYY] | --tipo error/warning/info | --ultimos N}" ;;
    esac
}

instalar_dhcp() {
    sudo apt update && sudo apt install isc-dhcp-server -y
    echo "Servicio DHCP instalado correctamente con APT."
}

instalar_ansible() {
    sudo apt update && sudo apt install ansible -y
    ansible-playbook -i localhost, ./ansible-dhcp/install_dhcp.yml
    echo "Servicio DHCP instalado correctamente con Ansible."
}

instalar_docker() {
    sudo apt update && sudo apt install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker
    docker build -t dhcp-server .
    docker run -d --name dhcp -p 67:67/udp dhcp-server
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
    sudo apt remove --purge -y docker.io
    sudo apt autoremove -y
    echo "Docker ha sido desinstalado correctamente."
}

configurar_dhcp() {
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
        instalar)
            shift
            seleccionar_instalacion "$@"
            ;;
        desinstalar)
            shift
            seleccionar_desinstalacion "$@"
            ;;
        servicio)
            shift
            gestionar_servicio "$@"
            ;;
        logs)
            shift
            consultar_logs "$@"
            ;;
        configurar_dhcp)
            configurar_dhcp
            ;;
        *)
            echo "Uso: $0 {instalar [docker|ansible|apt] | desinstalar [docker|ansible|apt] | servicio start|stop|restart|status | logs --recientes|--fecha YYYY-MM-DD|--tipo error|--ultimos N | configurar_dhcp}"
            ;;
    esac
    exit 0
fi

menu
