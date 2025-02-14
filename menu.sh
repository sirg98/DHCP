#!/bin/bash
while true
do
    # Menú de opciones
    echo "-----Servidor DHCP-----"
    echo "1.- Instalar"
    echo "2.- Desinstalar"
    echo "3.- Reiniciar"
    echo "4.- Estado"
    echo "5.- Info"
    echo "6.- Configuración"
    echo "7.- Salir"

    read -p "¿Qué necesitas?: " opcion

    if [ "$opcion" -eq 1 ]; then # Instalar DHCP
        sudo apt update -y
        sudo apt upgrade -y
        sudo apt install isc-dhcp-server -y
        sudo systemctl status isc-dhcp-server
        echo "El servicio DHCP se ha instalado correctamente"

    elif [ "$opcion" -eq 2 ]; then # Desinstalar
        sudo apt remove isc-dhcp-server -y
        sudo apt purge isc-dhcp-server -y
        echo "Se ha desinstalado correctamente"

    elif [ "$opcion" -eq 3 ]; then # Reiniciar
        sudo systemctl restart isc-dhcp-server
        echo "El servicio DHCP se ha reiniciado correctamente"
        sudo systemctl status isc-dhcp-server

    elif [ "$opcion" -eq 4 ]; then # Estado
        sudo systemctl status isc-dhcp-server

    elif [ "$opcion" -eq 5 ]; then # Información
        echo "El servicio DHCP asigna direcciones IP dinámicas en una red."

    elif [ "$opcion" -eq 6 ]; then # Configuración
        echo "Editando configuración..."
        sudo nano /etc/dhcp/dhcpd.conf

    elif [ "$opcion" -eq 7 ]; then # Salir
        echo "Saliendo..."
        break

    else
        echo "Opción incorrecta, prueba de nuevo eligiendo un número del menú."
    fi

    read -p "Presiona Enter para continuar..."
done
