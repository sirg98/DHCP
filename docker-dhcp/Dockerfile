FROM ubuntu:20.04

RUN apt update && apt install -y isc-dhcp-server

COPY dhcpd.conf /etc/dhcp/dhcpd.conf

CMD ["/usr/sbin/dhcpd", "-f"]
