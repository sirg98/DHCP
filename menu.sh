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
            3) sudo systemctl start isc-dhcp-server ;;
            4) sudo systemctl stop isc-dhcp-server ;;
            5) sudo systemctl restart isc-dhcp-server ;;
            6) consultar_logs ;;
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

consultar_logs() {
    echo "===== Opciones de logs ====="
    echo "1. Ver logs recientes"
    echo "2. Buscar logs por fecha"
    echo "3. Buscar logs por tipo"
    read -p "Elige una opción: " log_opcion

    case $log_opcion in
        1) journalctl -u isc-dhcp-server --since "1 hour ago" ;;
        2) read -p "Introduce la fecha (DD-MM-YYYY): " fecha
           journalctl -u isc-dhcp-server --since "$fecha 00:00:00" --until "$fecha 23:59:59" ;;
        3) read -p "Introduce el tipo de log (error, warning, info): " tipo
           journalctl -u isc-dhcp-server | grep -i "$tipo" ;;
        *) echo "Opción inválida";;
    esac
}

configurar_dhcp() {
    echo "Configurando DHCP..."
    read -p "Introduce la subred (ejemplo: 192.168.1.0): " subred
    read -p "Introduce la máscara de subred (ejemplo: 255.255.255.0): " mascara
    read -p "Introduce el rango de IPs inicial (ejemplo: 192.168.1.100): " rango_inicio
    read -p "Introduce el rango de IPs final (ejemplo: 192.168.1.200): " rango_fin
    read -p "Introduce la puerta de enlace (ejemplo: 192.168.1.1): " puerta_enlace
    read -p "Introduce el servidor DNS (ejemplo: 8.8.8.8): " dns

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
    sudo systemctl status isc-dhcp-server
}

configurar_netplan() {
    echo "Configurando Netplan..."
    read -p "Introduce la interfaz de red (ejemplo: enp0s3, eth0): " interfaz
    read -p "¿Quieres una IP estática o dinámica? (escribe 'estática' o 'dhcp'): " tipo_ip

    if [ "$tipo_ip" == "estática" ]; then
        read -p "Introduce la IP estática (ejemplo: 192.168.1.10/24): " ip_estatica
        read -p "Introduce la puerta de enlace (ejemplo: 192.168.1.1): " puerta_enlace
        read -p "Introduce el servidor DNS (ejemplo: 8.8.8.8): " dns

        sudo bash -c "cat > /etc/netplan/01-netplan.yaml" <<EOL
network:
  version: 2
  ethernets:
    $interfaz:
      addresses:
        - $ip_estatica
      routes:
        - to: default
          via: $puerta_enlace
      nameservers:
        addresses:
          - $dns
EOL
    elif [ "$tipo_ip" == "dhcp" ]; then
        sudo bash -c "cat > /etc/netplan/01-netplan.yaml" <<EOL
network:
  version: 2
  ethernets:
    $interfaz:
      dhcp4: true
EOL
    else
        echo "Opción inválida, por favor elige 'estática' o 'dhcp'."
        return
    fi

    echo "Aplicando configuración..."
    sudo netplan apply
    echo "Netplan configurado correctamente."
}

mostrar_info
menu

