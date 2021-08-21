#!/bin/bash
iptables -A FORWARD -o tun0 -i eth0 -s 192.168.1.0/24 -m conntrack --ctstate NEW -j ACCEPT
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A POSTROUTING -t nat -j MASQUERADE
iptables-save |  tee /etc/iptables.sav

openvpn --config client.ovpn --auth-user-pass client.pwd
