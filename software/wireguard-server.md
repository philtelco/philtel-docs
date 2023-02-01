# Configuring a WireGuard Server

To allow each of our phones to access the PhilTel network, we set up a Virtual Private Network (VPN) to allow a secure connection between each of our sites and our server running Asterisk.

We use WireGuard to facilitate connection between our main C&C server and each client site. Using this VPN, we can also easily administer the hardware at each site as we need.

WireGuard was chosen over OpenVPN due to its reliability, low latency, and ease of use. WireGuard is also considerably faster than OpenVPN but that doesn't matter much for our purposes because each site uses a low amount of data..

## Installing WireGuard

Assuming a Debian system, we will update and install WireGuard using a non-root, sudo user:

```
$ sudo apt update
$ sudo apt install wireguard
```

We will perform the following commands to create our public/private keypair:

```
$ wg genkey | sudo tee /etc/wireguard/private.key
$ sudo chmod go= /etc/wireguard/private.key
$ sudo cat /etc/wireguard/private.key | wg pubkey | sudo tee /etc/wireguard/public.key
```

Now we will create our config file:

```
$ sudo nano /etc/wireguard/wg0.conf
```

Our IP range will be `10.10.10.0/24` and we will listen on the default port `51820`:

```
[Interface]
Address = 10.10.10.1/24
ListenPort = 51820
PrivateKey = private_key_from_cat_command_above_goes_here
SaveConfig = false
PostUp = iptables -A FORWARD -i eth0 -o wg0 -j ACCEPT; iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i eth0 -o wg0 -j ACCEPT; iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
```

Note: we set `SaveConfig` as false as to not cache endpoint info from our peers. This could be problematic when their public IPs change.

Now, we must enable IPv4 forwarding on the server by modifying `/etc/sysctl.conf` and uncommenting `net.ipv4.ip_forward=1`. This will make sure that traffic can flow from our WireGuard peers through the server:

```
$ sudo cat /etc/sysctl.conf | grep 'net.ipv4.ip_forward=1'
net.ipv4.ip_forward=1
```

Then reload for changes to take effect:

```
$ sudo sysctl -p
```

Now, we can enable and start the`wg0` service via `systemd`:

```
$ sudo systemctl enable wg-quick@wg0.service
$ sudo systemctl start wg-quick@wg0.service
```

This will make sure that the service will run on reboot.

## Troubleshooting

Check the status of the service with the following:

```
$ sudo systemctl status wg-quick@wg0.service
```

Check the WireGuard connection with:

```
$ sudo wg show
```

Also, remember to create a firewall rule to open up the connection port, and a rule to accept all UDP traffic from our peers (ATAs can communicate with Asterisk on random UDP ports):

```
$ sudo cat /etc/iptables/rules.v4 | grep '51820'
-A INPUT -p udp --dport 51820 -j ACCEPT
```

```
$ sudo cat /etc/iptables/rules.v4 | grep '10.10.10.0'
-A INPUT -p udp -m udp -s 10.10.10.0/24 -j ACCEPT
```