#!/bin/bash

#menu de opciones
echo "-----Servidor DHCP-----"
echo "1.- Instalar"
echo "2.- Desinstalar"
echo "3.- Reiniciar"
echo "4.- Estado"
echo "5.- Info"
echo "6.- Configuración"

read -p "¿Qué necesitas?: " opcion

if [ $opcion -eq 1 ] #instalar dhcp
then 
	sudo apt update
	sudo apt upgrade
	sudo apt install isc-dhcp-server
	sudo systemctl status isc-dhcp-server
	echo "El servicio DHCP se ha instalado correctamente"
	
fi
if [ $opcion -eq 2 ] #desisntalar
then 
        sudo apt remove isc-dhcp-server
        sudo apt purge isc-dhcp-server
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
