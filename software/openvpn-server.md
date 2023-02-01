# Configuring an OpenVPN Server

To allow each of our phones to access the PhilTel network, we set up a Virtual Private Network (VPN) to allow a secure connection between each of our sites and our server running Asterisk.

We use OpenVPN to facilitate connection between our main C&C server and each client site. Using this VPN, we can also easily administer the hardware at each site as we need.

WireGuard proved to be unstable, so OpenVPN was brought in.

# IP Forwarding

We must enable IPv4 forwarding on the server by modifying `/etc/sysctl.conf` and uncommenting `net.ipv4.ip_forward=1`. This will make sure that traffic can flow from our OpenVPN peers through the server:

```
$ sudo cat /etc/sysctl.conf | grep 'net.ipv4.ip_forward=1'
net.ipv4.ip_forward=1
```

## Installation

```
$ wget https://raw.githubusercontent.com/Angristan/openvpn-install/master/openvpn-install.sh -O debian10-vpn.sh 
$ chmod +x debian10-vpn.sh 
$ sudo ./debian10-vpn.sh 
```

The script will automatically add the server port to the firewall and save the client `.ovpn` config file to your home directory. To revoke an existing client or add a new client, simply run the script again.

## Set a Static Client IP

It is useful to set a static IP for each client so we can easily identify them. We can extract the client name from the certificate and then add the needed IP info into a file in the `ccd` directory with the same name. Then, we restart the OpenVPN server.

```
$ sudo openssl x509 -subject -noout -in /etc/openvpn/easy-rsa/pki/issued/philtel-iffybooks.crt
subject=CN = philtel-iffybooks
$ sudo echo "ifconfig-push 10.8.0.2 255.255.255.0" > /etc/openvpn/ccd/philtel-iffybooks
$ sudo systemctl restart openvpn@server
```

## Troubleshooting

If needed we can always restart the server

```
$ sudo systemctl stop openvpn@server 
```

## Sources

* https://www.cyberciti.biz/faq/debian-10-set-up-openvpn-server-in-5-minutes/