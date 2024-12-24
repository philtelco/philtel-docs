# Exposing the Avocent MPU108E KVM

I have an old Avocent MPU108E KVM that I would like the make accessible remotely. However, this is an older, EOL device that probably shouldn't be exposed directly to the Internet. Here is the method I used to make it slightly more safely accessible.

This configuration consists of the KVM itself, an "inside" web server that proxies requests to the KVM, and an "outside" web server that access incoming connections from the Internet and proxies them to the inside server via an encrypted Wireguard VPN connection.

The most basic of diagrams for this setup can be shown below: 

[ KVM ] --- HTTPS --- [ Inside ] --- HTTP over Wireguard --- [ Outside ] --- HTTPS --- ( Internet )

## Inside Web Server

The KVM currently sits on my LAN with an IP of `192.168.3.43`. While the KVM can listen on port 443 for HTTPS or port 80 for HTTP, we will want to utilize port 443 for HTTPS.

### wireguard

Setting up a `wireguard` tunnel between the inside and outside servers is out-of-scope for this guide, but for reference we will use `10.10.10.200` as the IP for our inside server and `10.10.10.1` as the IP for our outside server.

### nginx

Using `nginx` on a machine on the same network, we can set up a proxy to access the KVM.

Assuming a Debian system, we will update and install `nginx` as a non-root, sudo user:

```
$ sudo apt update
$ sudo apt install nginx
```

Then set up our site config;

```
$ sudo cat /etc/nginx/sites-enabled/kvm_proxy

server {
  listen 10.10.10.200:8080;

  location / {
    proxy_pass https://192.168.3.43;
    include proxy_params;
  }
}
```

This is an HTML5-enabled KVM, and a quirk of that is we will be accessing an obscure port 4206 that seems to use HTTPS for our remote sessions.

To proxy this port we can make use of the `stream` block in `nginx.conf` which simply passes a TCP stream to our KVM with the caveat that we cannot make any modifications to the connection. This retains the SSL session back to the host (not possible with `iptables` prerouting/postrouting DNAT/SNAT rules) as for whatever reason we cannot use the same server-style config that we do for the web interface (this results in the KVM prematurely closing the connection for some reason).

Note that `192.168.3.43` is the IP address of the KVM on the local network.

```
$ sudo cat /etc/nginx/nginx.conf
...
stream {
 server {
    listen 10.10.10.200:4206;
    proxy_pass 192.168.3.43:4206;
  }
}
```

### iptables

Our inside server will connect via `wireguard` to an outside server that will face the Internet. We want to open the ports `nginx` is listening on to the interface that handles this connection.

```
$ sudo  cat /etc/iptables/rules.v4 | grep wg0
-A INPUT -i wg0 -m state --state RELATED,ESTABLISHED -j ACCEPT
-A INPUT -i wg0 -p tcp -m tcp --dport 8080 -j ACCEPT
-A INPUT -i wg0 -p tcp -m tcp --dport 4206 -j ACCEPT
-A INPUT -i wg0 -j DROP
```

## Outside Web Server

We have our Internet-facing server also running `nginx`. 

### wireguard

Again, the `wireguard` IP for our outside server is `10.10.10.1` while the IP for our inside server is `10.10.10.200`.

### nginx

Similar to the inside server, we will have a stream block to pass that port 4206 traffic back to our inside server.

```
$ sudo cat /etc/nginx/nginx.conf
...
stream {
 server {
    listen 4206;
    proxy_pass 10.10.10.200:4206;
  }
}
```

The `nginx` site config for the KVM web interface is a little more complex than what we saw on the inside server. 

1.	First thing to note is that we have an SSL certificate from Let's Encrypt managed by `certbot`. This SSL cert will renew every three months and encrypt the connection between the client and the outside server. More on setting this up soon. The connection between the outside and inside server are already encrypted over `wireguard`, and the connection between the inside server and KVM itself is HTTPS encrypted.
2.	We are leveraging basic auth to password protect incoming client connections. We will discuss how we generate the the `.htpasswd` file shortly.
3.	Before we proxy request back to the inside server, we will do a `mirror` to the `/notify` path. `/mirror` seems to be the more widely-used replacement for `/post_action`. Essentially, `/mirror` will invoke this path in the background which triggers a call to `http://127.0.0.1:8081/allowIp` passing in the client's IP address and port 4206. We will discuss the purpose of this call shortly.

So with this setup, any user loading up the URL will be presented with HTTP basic auth. If they successfully auth, requests will be forwarded (eventually) to the actual KVM but at the same time a request is made to an API running on `http://127.0.0.1:8081` which will open up port 4026 for that user and that user only.

```
$ sudo cat /etc/nginx/sites-available/kvm.philtel.org
server {
  listen [::]:443 ssl ipv6only=on; # managed by Certbot
  listen 443 ssl; # managed by Certbot
  ssl_certificate /etc/letsencrypt/live/kvm.philtel.org/fullchain.pem; # managed by Certbot
  ssl_certificate_key /etc/letsencrypt/live/kvm.philtel.org/privkey.pem; # managed by Certbot
  include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
  ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot

  server_name kvm.philtel.org;

  # Basic auth
  auth_basic "Login";
  auth_basic_user_file /etc/nginx/.htpasswd;

  # Proxy authenticated requests to the destination service
  location / {
	# Trigger background action after the request
    mirror /notify;

    proxy_pass http://10.10.10.200:8080;
    include proxy_params;
  }

  # Background subrequest to notify Node.js
  location = /notify {
      internal;

      # Forward to Node.js
      proxy_pass http://127.0.0.1:8081/allowIp;

      # Pass client IP address and the desired port
      proxy_set_header X-Client-IP $remote_addr;
      proxy_set_header X-Port 4206; # Replace 4206 with your desired port
  }
}

server {
    if ($host = kvm.philtel.org) {
        return 301 https://$host$request_uri;
    } # managed by Certbot


  listen 80;
  listen [::]:80;

  server_name kvm.philtel.org;
    return 404; # managed by Certbot

}
```

### certbot

We need a cert so install `nginx` and all the dependencies for Let's Encrypt:

```
# apt install python3-acme python3-certbot python3-mock python3-openssl python3-pkg-resources python3-pyparsing python3-zope.interface
# apt install python3-certbot-nginx
```

Assume an existing config file like:

```
# cat /etc/nginx/sites-enabled/kvm.philtel.org
server {
  server_name kvm.philtel.org
  listen 80;

  location / {
    proxy_pass http://10.10.10.200:8080;
    include proxy_params;
  }
}
```

Run `certbot` to generate the certificate:

```
# certbot --nginx -d kvm.philtel.org
```

Restart `nginx`:

```
# systemctl restart nginx
```

Upon cert renewals `nginx` should be reloaded automatically.

### .htpasswd

Users will be granted access to the KVM (in addition to the KVM's built-in user/password auth) via credentials added to `.htpasswd`.

We will create this file by generating a password for our first user. Note the flags used here. `-c` is used to create, `-B` is used to specify `bcrypt` hashing, and `-C 14` sets complexity. A value of `14` for complexity means each authentication attempt should take about one second which significantly slows down brute-force attacks. Alternatively (or supplementally), we could leverage `fail2ban` to ban clients after too many incorrect attempts.

```
$ sudo htpasswd -c -B -C 14 /etc/nginx/.htpasswd famicoman
```

To add additional hashes, we could request them from our users and append the file with them, or generate them with the same command omitting the `-c` flag.

### allowIP API

I decided to write an API in Node.js because I felt like that was better than writing and running PHP. This API simply accepts an IP and a port number and allows that IP access to that port if it isn't already allowed. I don't worry about removing entries as the attack vector for not doing so is mostly going to be people who already have access, nor do I worry about persistence because users can easily re-auth by creating a new session.

To run this script we need `node`:

```
$ sudo apt install -y nodejs npm
```

Now we will make a new project in `/opt/access-manager/`:

```
$ mkdir /opt/access-manager
$ cd /opt/access-manager
```

Now init the project:

```
$ npm init
```

We have our `package.json`:

```
$ cat package.json`
{
  "name": "access-manager",
  "version": "1.0.0",
  "description": "Delegate access to clients",
  "main": "app.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "author": "Mike Dank",
  "license": "UNLICENSED",
  "dependencies": {
    "express": "^4.21.2"
  }
}
```

Our `app.js` looks like this:

```
$ cat app.js
const express = require('express');
const { exec } = require('child_process');

const app = express();

app.use(express.json());

app.get('/allowIp', (req, res) => {
    const clientIp = req.headers['x-client-ip'];
    const port = req.headers['x-port'];

    // Validate the client IP format
    const isValidIp = /^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/.test(clientIp);

    if (!isValidIp) {
        console.error(`Invalid IP address: ${clientIp}`);
        return res.status(400).send('Invalid IP address');
    }

    // Validate the port number (1–65535)
    const isValidPort = /^\d+$/.test(port) && +port >= 1 && +port <= 65535;
    if (!isValidPort) {
        console.error(`Invalid port: ${port}`);
        return res.status(400).send('Invalid port');
    }

    console.log(`Received request to allow IP: ${clientIp} on port: ${port}`);

    // Command to check if iptables rule exists
    const checkCommand = `iptables -C INPUT -p tcp -s ${clientIp} --dport ${port} -j ACCEPT`;

    exec(checkCommand, (checkError, stdout, stderr) => {
        if (!checkError) {
            console.log(`Rule already exists for ${clientIp} on port ${port}`);
            return res.status(200).send(`Rule already exists for ${clientIp} on port ${port}`);
        }

        // Rule does not exist; proceed to add it

        const command = `iptables -I INPUT -p tcp -s ${clientIp} --dport ${port} -j ACCEPT`;

        exec(command, (error, stdout, stderr) => {
            if (error) {
                console.error(`Error adding iptables rule: ${error.message}`);
                return res.status(500).send('Failed to update iptables');
            }

            console.log(`iptables rule added for ${clientIp} on port ${port}: ${stdout}`);
            res.send(`Access granted to ${clientIp} on port ${port}`);
        });
    });
});

// Start the server
app.listen(8081, () => {
    console.log('Node.js service running on port 8081');
});
```

Now we need to install the dependencies:

```
$ npm install
```

We want to run this on boot, so let's make a `systemd` unit file.

```
$ sudo cat /etc/systemd/system/access-manager.service
[Unit]
Description=Node.js Service to Manage iptables Rules
After=network.target

[Service]
ExecStart=/usr/bin/node /opt/access-manager/app.js
Restart=always
User=root
Group=root
Environment=NODE_ENV=production
WorkingDirectory=/opt/access-manager

[Install]
WantedBy=multi-user.target
```

Now let's enable and start it:

```
$ sudo systemctl daemon-reload
$ sudo systemctl enable access-manager
$ sudo systemctl start access-manager
```

### iptables

Make sure that ports 80/443 are open:

```
$ cat /etc/iptables/rules.v4
...
-A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 443 -j ACCEPT
```

## Avocent KVM

To make the KVM happy, because it uses HSTS for the sessions over port 4026, we need to supply it with the `kvm.philtel.org` cert with the private key.

On the outside server we can create the proper file by running the following:

```
$ sudo cat /etc/letsencrypt/live/kvm.philtel.org/fullchain.pem /etc/letsencrypt/live/kvm.philtel.org/privkey.pem > out.pem
```

Then we can move `out.pem` to somewhere that can be accessed on the machine we will use to connect to the KVM via browser.

Now on the KVM, log in and go to *Appliance* -> *Overview* and click on *Manage Appliance Web Certificate*. On the following page, click on the *Update* button. Then select the radio button for *Upload a New Certificate* and browse for the `out.pem` file. Then click the *Upload* button.

Unfortunately there does not appear to be an option to trigger retrievals of this cert file from the KVM so this is a manual process that needs to be done quarterly. 