# Rsyslog with TLS

For some devices, we want to grab syslogs via the Internet, so let's make sure they are encrypted with TLS.

Let's install some dependencies and grab a certificate using Let's Encrypt `certbot`:

```
$ sudo apt install nginx python3-acme python3-certbot python3-mock python3-openssl python3-pkg-resources python3-pyparsing python3-zope.interface rsyslog-gnutls
$ sudo apt install python3-certbot-nginx
$ sudo certbot certonly --nginx -d syslog.philtel.org --deploy-hook "systemctl restart rsyslog.service"
```

The `deploy-hook` argument specifies a command that should run on every successful renewal of the certificate. We don't really care about `nginx` here and are essentially piggy-backing on it for the renewal challenge, but we will be ingesting this cert in `rsyslog` so we need to make sure it gets restarted.

We can verify the deploy hook is present by checking the renewal config:

```
$ cat /etc/letsencrypt/renewal/syslog.philtel.org.conf
...
[renewalparams]
...
renew_hook = systemctl restart syslog.service
```

Now we edit `rsyslog.conf`:

```
$ sudo nano /etc/rsyslog.conf
```

We can add the TLS config after existing input config, but we also want to update TCP to use `imptcp` while TLS will use `imtcp`:

```
# https://www.rsyslog.com/doc/v8-stable/configuration/modules/imudp.html
module(load="imudp")
input(type="imudp" port="514" ruleset="remote")

# https://www.rsyslog.com/doc/v8-stable/configuration/modules/imtcp.html
module(load="imptcp")
input(type="imptcp" port="514" ruleset="remote")

#### TLS ####
module(load="imtcp" # TCP listener
    StreamDriver.Name="gtls"
    StreamDriver.Mode="1" # run driver in TLS-only mode
    StreamDriver.Authmode="anon"
    )
# Define the certificate files
global(
    DefaultNetstreamDriver="gtls"
    DefaultNetstreamDriverCAFile="/etc/letsencrypt/live/syslog.philtel.org/fullchain.pem"
    DefaultNetstreamDriverCertFile="/etc/letsencrypt/live/syslog.philtel.org/fullchain.pem"
    DefaultNetstreamDriverKeyFile="/etc/letsencrypt/live/syslog.philtel.org/privkey.pem"
)
# Enable TCP listener
input(type="imtcp" port="6514" ruleset="remote")

```

Add an `iptables` rule:

```
$ sudo cat /etc/iptables/rules.v4
...
-A INPUT -p tcp -m tcp --dport 6514 -j ACCEPT
```

Restart `rsyslog`:

```
$ sudo systemctl restart rsyslog
```