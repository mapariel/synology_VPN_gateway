# Use Synology NAS as a Gateway to VPN network

Imagine that you want your TV to connect to a VPN, in order to watch Netflix programmes from another country. You can use your Synology NAS as a VPN client and as a gateway quite easily [1]. The issue here is that you have to start the client everytime you want to use it and to stop it afterward. You probably don't want it to be constantly connected to a VPN.

Here is a solution based on Docker container.


## Structure of the folder

The folder contain those files.

```
Synology_VPN_gateway
├── client.ovpn
├── client.pwd
├── docker-compose.yml
├── Dockerfile
├── script.sh
└── sysctl.conf
```

You shouldn't have to modify the files that already exist. But you have to add **client.ovpn**  which is the ovpn file that you can get from your VPN provider and
**client.pwd*** which contains your connection informations to the VPN. First line is the username, second line is the password. For instance :
```
toto
ultras3cr3t
```


## Installation on the NAS

We are going to use docker-compose https://docs.docker.com/compose/ . If you can install docker on your NAS, then you will have docker-compose automatically.

Make an archive of the folder **Synology_VPN_gateway**, upload it somewhere on your NAS. One in the NAS, unzip it.

Then connect to the NAS with SSH and navigate to the foler **Synology_VPN_gateway**.

To create the conatiner just type.
`docker-compose up --build -detach`

The  IP of the container on your local network  should be visible.


## If it doesn't work (docker-compose.yml)

If the process encounters an error, it might be that you have to modify the **docker-compose.yml** file:

This configuration works fine for my NAS. You can change the port where the application runs (here it is **4923**). Make sure that this port is not already used by another docker container. 
Also the parent (here **ovs_eth0**) has to match with the name network interface you are going to use. Run **ifconfig** command on your NAS to check.

```
version: "3.7"
services:
  vpn:
    build: .
    restart: always
    networks:
      - myvlan    
    cap_add:
      - NET_ADMIN
    tty: true       # -i
    stdin_open: true # -t
    ports:
      - "4923:80"
    container_name: my_vpn
    
networks:
  private:
  myvlan:
    driver: macvlan
    driver_opts:
      parent: ovs_eth0
    ipam:
      config:
        - subnet: 192.168.1.0/24

```

You can also inspect your container to see if the network part is correct. Check the MacAddress and the IPAddress of your container on your local network.

`$ docker container inspect my_vpn`

```
...truncated...
"Networks": {
  "my-macvlan-net": {
      "IPAMConfig": null,
      "Links": null,
      "Aliases": [
          "bec64291cd4c"
      ],
      "NetworkID": "5e3ec79625d388dbcc03dcf4a6dc4548644eb99d58864cf8eee2252dcfc0cc9f",
      "EndpointID": "8caf93c862b22f379b60515975acf96f7b54b7cf0ba0fb4a33cf18ae9e5c1d89",
      "Gateway": "192.168.1.1",
      "IPAddress": "192.168.1.2",
      "IPPrefixLen": 24,
      "IPv6Gateway": "",
      "GlobalIPv6Address": "",
      "GlobalIPv6PrefixLen": 0,
      "MacAddress": "02:42:ac:10:56:02",
      "DriverOpts": null
  }
}
...truncated
```



## The other files

You shouldn't have to modify those files.

### script.sh

This script will be launched right after the container has been launched.
It contains the modifications of the iptable (to make it a bridge), and at the end connects to the VPN.

You can find explanations about those instructions at https://support.hidemyass.com/hc/en-us/articles/202721486-Using-Linux-Virtual-Machine-instead-of-a-router-for-VPN and at https://help.ubuntu.com/community/Internet/ConnectionSharing

```
#!/bin/bash
iptables -A FORWARD -o tun0 -i eth0 -s 192.168.1.0/24 -m conntrack --ctstate NEW -j ACCEPT
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A POSTROUTING -t nat -j MASQUERADE
iptables-save |  tee /etc/iptables.sav

mkdir -p /dev/net
mknod /dev/net/tun c 10 200
chmod 600 /dev/net/tun

openvpn --config client.ovpn --auth-user-pass client.pwd
```

### sysctl.conf

This file will replace one configuration file. Only one line has to be uncommented. No need to reproduce the content here. Just pick it from the repository.

### Dockerfile

The container comes from an ubuntu container. It installs some packages (openvpn and iptables), copies some files and then run the script.

```
FROM ubuntu
RUN apt-get update
RUN apt-get -y install openvpn iptables
# RUN apt-get -y install net-tools curl
WORKDIR /etc/ovpn
COPY  client.ovpn /etc/ovpn/client.ovpn 
COPY client.pwd /etc/ovpn/client.pwd
COPY sysctl.conf  /etc/sysctl.conf
COPY ./script.sh .
RUN chmod +x ./script.sh
ENTRYPOINT ["./script.sh"]
```

## Links

[1]: https://kb.synology.com/en-global/DSM/help/DSM/AdminCenter/connection_network_vpnclient?version=6
1: https://kb.synology.com/en-global/DSM/help/DSM/AdminCenter/connection_network_vpnclient?version=6

https://www.kernel.org/doc/html/latest/networking/tuntap.html
