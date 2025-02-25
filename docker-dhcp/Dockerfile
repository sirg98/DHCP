FROM ubuntu:22.04

RUN sed -i '/security.ubuntu.com/d' /etc/apt/sources.list && \
    apt update && \
    apt install -y isc-dhcp-server iproute2 && \
    apt clean

RUN mkdir -p /var/lib/dhcp && \
    touch /var/lib/dhcp/dhcpd.leases

COPY dhcpd.conf /etc/dhcp/dhcpd.conf

EXPOSE 67/udp

CMD ["/usr/sbin/dhcpd", "-f", "-d", "-cf", "/etc/dhcp/dhcpd.conf"]
