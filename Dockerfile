FROM ubuntu
RUN apt-get update
RUN apt-get -y install openvpn iptables nano net-tools 
WORKDIR /etc/ovpn
COPY  client.ovpn /etc/ovpn/client.ovpn 
COPY client.pwd /etc/ovpn/client.pwd
COPY sysctl.conf  /etc/sysctl.conf
COPY ./script.sh .
RUN chmod +x ./script.sh
ENTRYPOINT ["./script.sh"]


