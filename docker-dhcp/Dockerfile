FROM ubuntu:22.04

# Eliminar completamente las referencias a security.ubuntu.com
RUN sed -i '/security.ubuntu.com/d' /etc/apt/sources.list && \
    apt update && \
    apt install isc-dhcp-server -y

COPY dhcpd.conf /etc/dhcp/dhcpd.conf
EXPOSE 67/udp
CMD ["/usr/sbin/dhcpd", "-f", "-d"]
