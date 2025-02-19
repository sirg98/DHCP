#!/bin/bash

while true
do
    # Menú de opciones
    echo "---------- Servidor DHCP ---------"
    echo "1.- Actualizar sistema"
    echo "2.- Instalar DHCP"
    echo "3.- Desinstalar DHCP"
    echo "4.- Reiniciar DHCP"
    echo "5.- Estado del servicio DHCP"
    echo "6.- Configurar DHCP"
    echo "7.- Configurar Netplan"
    echo "8.- Corregir permisos de Netplan"
    echo "9.- Ayuda (--help)"
    echo "10.- Salir"
    echo "---------------------------------"

    read -r -p "¿Qué necesitas?: " opcion

    if [ "$opcion" -eq 1 ]; then # Actualizar sistema
        sudo apt update --help
        sudo apt update -y
        sudo apt upgrade --help
        sudo apt upgrade -y
        echo "El sistema se ha actualizado correctamente."

    elif [ "$opcion" -eq 2 ]; then # Instalar DHCP
        sudo apt install isc-dhcp-server -y
        sudo systemctl status isc-dhcp-server
        echo "El servicio DHCP se ha instalado correctamente."

    elif [ "$opcion" -eq 3 ]; then # Desinstalar
        sudo apt remove isc-dhcp-server -y
        sudo apt purge isc-dhcp-server -y
        echo "Se ha desinstalado correctamente."

    elif [ "$opcion" -eq 4 ]; then # Reiniciar DHCP
        sudo systemctl restart isc-dhcp-server
        echo "El servicio DHCP se ha reiniciado correctamente."
        sudo systemctl status isc-dhcp-server

    elif [ "$opcion" -eq 5 ]; then # Estado del servicio
        sudo systemctl status isc-dhcp-server

    elif [ "$opcion" -eq 6 ]; then # Configuración DHCP
        echo "Configurando DHCP..."
        read -r -p "Introduce la subred (ejemplo: 192.168.1.0): " subred
        read -r -p "Introduce la máscara de subred (ejemplo: 255.255.255.0): " mascara
        read -r -p "Introduce el rango de IPs inicial (ejemplo: 192.168.1.100): " rango_inicio
        read -r -p "Introduce el rango de IPs final (ejemplo: 192.168.1.200): " rango_fin
        read -r -p "Introduce la puerta de enlace (ejemplo: 192.168.1.1): " puerta_enlace
        read -r -p "Introduce el servidor DNS preferido (ejemplo: 8.8.8.8): " dns

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

    elif [ "$opcion" -eq 7 ]; then # Configurar Netplan
        echo "Configurando Netplan..."
        read -r -p "Introduce la interfaz de red (ejemplo: enp0s3, eth0): " interfaz
        read -r -p "¿Quieres una IP estática o dinámica? (escribe 'estatica' o 'dhcp'): " tipo_ip

        if [ "$tipo_ip" == "estatica" ]; then
            read -r -p "Introduce la IP estática (ejemplo: 192.168.1.10/24): " ip_estatica
            read -r -p "Introduce la puerta de enlace (ejemplo: 192.168.1.1): " puerta_enlace
            read -r -p "Introduce el servidor DNS (ejemplo: 8.8.8.8): " dns

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
            echo "Opción inválida, por favor elige 'estatica' o 'dhcp'."
            continue
        fi

        echo "Aplicando configuración..."
        sudo netplan apply
        echo "Netplan configurado correctamente."

    elif [ "$opcion" -eq 8 ]; then # Corregir permisos de Netplan
        echo "Corrigiendo permisos en Netplan..."
        sudo chown root:root /etc/netplan/01-netplan.yaml
        sudo chmod 600 /etc/netplan/01-netplan.yaml
        sudo netplan apply
        echo "Permisos corregidos y Netplan aplicado correctamente."

    elif [ "$opcion" -eq 9 ]; then # Ayuda (--help)
        echo "Uso del programa:"
        echo "Este script permite instalar, configurar y gestionar un servidor DHCP en Ubuntu."
        echo ""
        echo "Opciones del menú:"
        echo "  1. Actualizar sistema - Ejecuta 'apt update' y 'apt upgrade'."
        echo "  2. Instalar DHCP - Instala el servicio DHCP."
        echo "  3. Desinstalar DHCP - Elimina el servidor DHCP."
        echo "  4. Reiniciar DHCP - Reinicia el servicio DHCP."
        echo "  5. Estado del servicio DHCP - Muestra el estado del servicio DHCP."
        echo "  6. Configurar DHCP - Permite definir los parámetros para la red."
        echo "  7. Configurar Netplan - Configura la red."
        echo "  8. Corregir permisos de Netplan - Ajusta permisos."
        echo "  9. Ayuda - Muestra este mensaje."
        echo "  10. Salir - Sale del programa."

    elif [ "$opcion" -eq 10 ]; then # Salir
        echo "Saliendo..."
        break

    else
        echo "Opción incorrecta, prueba de nuevo eligiendo un número del menú."
    fi

    read -r -p "Presiona Enter para continuar..."
done
