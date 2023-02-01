# Setting up WireGuard on the GL-AR300M16

## Installing WireGuard

`ssh` into your router at `192.168.1.1`. 

Note: Make sure you set a password for root before doing this step, you will not be able to perform an update until you do.

```
$ ssh root@192.168.1.1
```

Next, perform an update and install WireGuard packages:

```
# opkg update
# opkg install wireguard-tools luci-proto-wireguard
```

Next generate the public/private keys and save the output for later, we will need the private key for our client set up and the public key for our server setup.

```
# wg genkey | tee privatekey | wg pubkey > publickey
# cat privatekey && cat publickey
```

Finally, reboot. You must perform this step before adding an interface.

```
# reboot
```

## Configuring an Interface

After a few minutes the router should be rebooted. Navigate to the web interface at http://192.168.1.1 and go to *Network* --> *Interfaces*. Near the bottom of the screen press the button for *Add New Interface...* In the dialog, name the interface `philtel` and set the protocol to `WireGuard VPN` before pressing the *Create Interface* button.

On the *Interfaces* dialog, check the box for *Bring up on boot* and enter the private key we saved earlier into the corresponding field. In the box next to *IP Addresses*, we will put in an address in our server's advertised range such as `10.10.10.2`.

On the *Advanced Settings* tab, make sure the box for *Use default gateway* is checked.

On the *Peers* tab, enter `philtel-server` in the *Description* field and enter the server's public key in the *Public Key* field. For *Allowed IPs*, enter `0.0.0.0/0` and make sure the box is checked for *Route Allowed IPs*. For the *Endpoint Host*, enter the public IP address of the server and for *Endpoint Port* use the port the server is running WireGuard on (likely `51820`). Finally, enter `25` into the field for *Persistent Keep Alive* to have our client constantly keep the connection active since the server will not know of the client's IP/Port to start a connection.

Finally, press the *Save* button and when the dialog disappears, press the *Save & Apply* button on the *Interfaces* page.

## Configuring the Firewall

We want to pass all traffic through WireGuard and also allow connections direct to the WireGuard server so we must make changes in the firewall.

Navigate to *Network* --> *Firewall* and press the *Add* button in the *Zones* section of the page.

In the *Name* field enter `philtel_fw`. From the *Input* dropdown choose `Reject`, from the *Output* dropdown choose `Accept`, and from the *Forward* dropdown choose `Reject`.

Check the boxes for *Masquerading* and *MSS clamping*. In *Covered Networks* select `philtel`. For *Allow Forward to destination zones* leave this as `unspecified` but for *Allow forward from source zones* select `lan`.

Press the button for *Save* and then on the *Firewall* page press the button for *Save & Apply*.

Afterwards from any LAN client connected to the router should be able to ping a public IP and the internal IP of our WireGuard server:

```
> ping 1.1.1.1
> ping 10.10.10.1
```

## Adding the Peer to the Server

On our server, we just need to edit the config for the new peer.

```
$ sudo nano /etc/wireguard/wg0.conf
```

Paste the following into the bottom of the file, substituting the client's `PublicKey` and `AllowedIPs` with what we set previously at the client:

```
[Peer]
PublicKey = xxxxxxxxxx
AllowedIPs = 10.10.10.2/32
PersistentKeepalive = 25
```

Now, we simply restart WireGuard on the server to load the new config:

```
$ sudo systemctl reload wg-quick@wg0.service
```

## Workarounds for Wireguard not getting RX 

We noticed after downtime/reboots that the WireGuard interface on the router will appear to connect and send TX, but it will not get any RX back. The temporarily solution for this was to up/down the interface on the server side, but this is a bad fix as it has to be done manually and power outages can never be predicted. There should not need to be human intervention for reconnection.  

A similar issue was reported in this thread and workarounds were provided, https://forum.openwrt.org/t/wireguard-not-re-establishing-connection/90556/3  

NOTE: After applying the below workarounds, complete reconnection after a power cycle may take up to 3 minutes (could be more).  

To apply these workarounds, SSH into the router (`ssh 192.168.1.1`) and login with `root`. Now, execute these three sets of commands:  

###Dynamic connection

Preserve default route to restore WAN connectivity when VPN is disconnected.

```
# Preserve default route
uci set network.wan.metric="1024"
uci commit network
/etc/init.d/network restart
```

### Dynamic address

Periodically re-resolve inactive peer hostnames for VPN peers with dynamic IP addresses.

```
# Periodically re-resolve inactive peers
cat << "EOF" >> /etc/crontabs/root
* * * * * /usr/bin/wireguard_watchdog
EOF
uci set system.@system[0].cronloglevel="9"
uci commit system
/etc/init.d/cron restart
```

### Race conditions

Resolve the race condition with `sysntpd` service when RTC is missing.

```
# Resolve race conditions
cat << "EOF" >> /etc/crontabs/root
* * * * * date -s 2030-01-01; /etc/init.d/sysntpd restart
EOF
uci set system.@system[0].cronloglevel="9"
uci commit system
/etc/init.d/cron restart
```

## Troubleshooting

At any point, check the status of the WireGuard link with `wg show`.

Now, the client and server should handhshake but it may be necessary to restart the interface via OpenWRT the first time. In the OpenWRT GUI, go to *Network* --> *Interfaces* and press the *Restart* button next to the `philtel` interface. Within a few seconds the interface should come back up.

To test connectivity feel free to ping the server from the client or the client from the server using the `10.10.10.x` addresses.
