FROM ubuntu:22.04

# Configurar el DNS para evitar problemas de resolución
RUN echo "nameserver 8.8.8.8" > /etc/resolv.conf && \
    echo "nameserver 8.8.4.4" >> /etc/resolv.conf

# Eliminar referencias a security.ubuntu.com y actualizar antes de instalar
RUN sed -i '/security.ubuntu.com/d' /etc/apt/sources.list && \
    apt update && \
    apt install -y isc-dhcp-server iproute2 && \
    apt clean

# Crear directorio y archivo de arrendamientos
RUN mkdir -p /var/lib/dhcp && \
    touch /var/lib/dhcp/dhcpd.leases

# Copiar la configuración del servidor DHCP
COPY dhcpd.conf /etc/dhcp/dhcpd.conf

# Exponer el puerto 67/udp necesario para DHCP
EXPOSE 67/udp

# Comando por defecto para iniciar el servidor DHCP
CMD ["/usr/sbin/dhcpd", "-f", "-d", "-cf", "/etc/dhcp/dhcpd.conf"]
