#!/bin/bash
while true
do
	#menu de opciones
	echo "-----Servidor DHCP-----"
	echo "1.- Instalar"
	echo "2.- Desinstalar"
	echo "3.- Reiniciar"
	echo "4.- Estado"
	echo "5.- Info"
	echo "6.- Configuración"
	echo "7.- Salir"

	read -p "¿Qué necesitas?: " opcion

	if [ $opcion -eq 1 ] #instalar dhcp
	then 
		sudo apt update -y
		sudo apt upgrade -y
		sudo apt install isc-dhcp-server -y
		sudo systemctl status isc-dhcp-server
		echo "El servicio DHCP se ha instalado correctamente"
	
	fi
	if [ $opcion -eq 2 ] #desisntalar
	then 
        	sudo apt remove isc-dhcp-server -y
        	sudo apt purge isc-dhcp-server -y
        	echo "Se ha desinstalado correctamente"
	fi

	if [ $opcion -eq 3 ] #reiniciar
	then
        	sudo systemctl restart isc-dhcp-server
        	echo "El servicio DHCP se ha reiniciado correctamente"
		sudo systemctl status isc-dhcp-server
	fi

	if [ $opcion -eq 4 ] # status
	then
        	sudo systemctl status isc-dhcp-server
	fi

	if [ $opcion -eq 6 ]
    	then
        	echo "Editando configuración"
        	sudo nano /etc/dhcp/dhcpd.conf
	fi
    	if [ $opcion -eq 7 ]
    	then
        	echo "Saliendo..."
        	break
		echo "Opción incorrecta, prueba de nuevo eligiendo un caracter del menú."
    	fi
	read
done
