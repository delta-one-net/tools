#!/bin/bash

# requirements:
# - iproute2
# - dhcpd

# to the internet (upstream)
WAN_IF=enp0s3
# stuff to be proxied (downstream)
LAN_IF=enp0s8

# LAN Subnet
LAN_SUBNET=192.168.179

# set ip of lan interface
ip a add $LAN_SUBNET.1/24 dev $LAN_IF

# enable ip forward
echo 1 > /proc/sys/net/ipv4/ip_forward

# nat and masq traffic from LAN_SUBNET.0/24 subnet
iptables -t nat -A POSTROUTING -o $WAN_IF -s $LAN_SUBNET.0/24 -j MASQUERADE --random

# allow forwarding new connections from LAN to WAN
# with source ip in the defined subnet
iptables -A FORWARD -i $LAN_IF -o $WAN_IF -s $LAN_SUBNET.0/24 \
    -m conntrack --ctstate NEW -j ACCEPT

# allow all established or related traffic (from WAN to LAN)
iptables -A FORWARD -i $WAN_IF -o $LAN_IF -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

echo "
subnet $LAN_SUBNET.0 netmask 255.255.255.0 {
    option routers $LAN_SUBNET.1;
    option domain-name-servers 1.1.1.1;
    option subnet-mask 255.255.255.0;
    range $LAN_SUBNET.10 $LAN_SUBNET.200;
}" > /etc/dhcp/dhcpd.$LAN_IF.conf

dhcpd -cf /etc/dhcp/dhcpd.$LAN_IF.conf $LAN_IF
