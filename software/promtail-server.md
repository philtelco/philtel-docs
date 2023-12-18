# Configuring an Rsyslog/Promtail Server for Grafana Loki

To capture logs from our hardware, we will set up `rsyslog` and `promtail` to ingest into Grafana Loki.

## Promtail Installation

Download the latests `promtail` version and extract it:

```
# apt install unzip
# cd /usr/local/bin
# wget https://github.com/grafana/loki/releases/download/v2.8.6/promtail-linux-amd64.zip
# unzip promtail*
# mv promtail-linux-amd64 promtail
# rm *.zip
```

Next, we will create a `systemd` service:

```
$ sudo nano /etc/systemd/system/promtail.service
[Unit]
Description=Promtail syslog relay

[Service]
User=root
ExecStart=/usr/local/bin/promtail --config.file=/etc/promtail-syslog.yml

[Install]
WantedBy=multi-user.target
```

Now, we can create the configuration file:

```
$sudo nano /etc/promtail-syslog.yml
server:
  http_listen_port: 9081
  grpc_listen_port: 0

positions:
  filename: /tmp/promtail-syslog-positions.yml

clients:
  - url: https://youraccountid:yourkey@yourserver.grafana.net/api/prom/push

scrape_configs:
  - job_name: syslog
    syslog:
      listen_address: 0.0.0.0:1514
      labels:
        job: syslog
    relabel_configs:
      - source_labels: [__syslog_message_hostname]
        target_label: hostname
      - source_labels: [__syslog_message_severity]
        target_label: level
      - source_labels: [__syslog_message_app_name]
        target_label: application
      - source_labels: [__syslog_message_facility]
        target_label: facility
      - source_labels: [__syslog_connection_hostname]
        target_label: connection_hostname

#scrape_configs:
#- job_name: system
#  static_configs:
#  - targets:
#      - localhost
#    labels:
#      job: varlogs
#      __path__: /var/log/remote/*.log
```

Then start and enable the service:

```
$ sudo systemctl daemon-reload
$ sudo systemctl enable --now promtail
```

## Rsyslog Installation

Now that we have Promtail set up, we can set up Rsyslog to listen for logs and relay them to Promtail.

First we can install `rsyslog`:

```
$ sudo apt install -y rsyslog
```

Now we can set up the configuration. Note that the rules for our ATAs are defined explicitly as the hostname is always reported to be `HT8XX` instead of the hostname we defined in ATA configuration. Because of this we manually maintain a mapping of MAC address and device to cleaner logging.

```
$ sudo nano /etc/rsyslog.conf
# /etc/rsyslog.conf configuration file for rsyslog
#
# For more information install rsyslog-doc and see
# /usr/share/doc/rsyslog-doc/html/configuration/index.html


#################
#### MODULES ####
#################

module(load="imuxsock") # provides support for local system logging
module(load="imklog")   # provides kernel logging support
#module(load="immark")  # provides --MARK-- message capability

template(name="openwrtTemplate" type="string" string="/var/log/remote/%hostname%.log")

ruleset(name="remote"){
  # https://www.rsyslog.com/doc/v8-stable/configuration/modules/omfwd.html
  # https://grafana.com/docs/loki/latest/clients/promtail/scraping/#rsyslog-output-configuration
  action(type="omfwd" Target="localhost" Port="1514" Protocol="tcp" Template="RSYSLOG_SyslogProtocol23Format" TCP_Framing="octet-counted"
    queue.type="LinkedList"
    queue.size="100000"
    queue.filename="philtel-remote-queue"
    queue.saveonshutdown="on"
    queue.maxdiskspace="100m"
    action.resumeRetryCount="-1"
    action.resumeInterval="30"
    action.resumeIntervalMax="604800"
  )
  if $msg contains ' HT801 [c0:74:ad:5c:9a:7f]' then {
    action(type="omfile" file="/var/log/remote/ht801-miketest.log")
  } else if $msg contains ' HT801 [c0:74:ad:35:5b:f8]' then {
    action(type="omfile" file="/var/log/remote/ht801-iffybooks.log")
  } else if $HOSTNAME contains 'openwrt-' then {
    action(type="omfile" dynafile="openwrtTemplate")
  } else {
    action(type="omfile" file="/var/log/remote/default.log")
  }
}


# https://www.rsyslog.com/doc/v8-stable/configuration/modules/imudp.html
module(load="imudp")
input(type="imudp" port="514" ruleset="remote")

# https://www.rsyslog.com/doc/v8-stable/configuration/modules/imtcp.html
module(load="imtcp")
input(type="imtcp" port="514" ruleset="remote")

###########################
#### GLOBAL DIRECTIVES ####
###########################

#
# Use traditional timestamp format.
# To enable high precision timestamps, comment out the following line.
#
$ActionFileDefaultTemplate RSYSLOG_TraditionalFileFormat

#
# Set the default permissions for all log files.
#
$FileOwner root
$FileGroup adm
$FileCreateMode 0640
$DirCreateMode 0755
$Umask 0022

#
# Where to place spool and state files
#
$WorkDirectory /var/spool/rsyslog

#
# Include all config files in /etc/rsyslog.d/
#
$IncludeConfig /etc/rsyslog.d/*.conf


###############
#### RULES ####
###############

#
# First some standard log files.  Log by facility.
#
auth,authpriv.*                 /var/log/auth.log
*.*;auth,authpriv.none          -/var/log/syslog
#cron.*                         /var/log/cron.log
daemon.*                        -/var/log/daemon.log
kern.*                          -/var/log/kern.log
lpr.*                           -/var/log/lpr.log
mail.*                          -/var/log/mail.log
user.*                          -/var/log/user.log

#
# Logging for the mail system.  Split it up so that
# it is easy to write scripts to parse these files.
#
mail.info                       -/var/log/mail.info
mail.warn                       -/var/log/mail.warn
mail.err                        /var/log/mail.err

#
# Some "catch-all" log files.
#
*.=debug;\
        auth,authpriv.none;\
        mail.none               -/var/log/debug
*.=info;*.=notice;*.=warn;\
        auth,authpriv.none;\
        cron,daemon.none;\
        mail.none               -/var/log/messages

#
# Emergencies are sent to everybody logged in.
#
*.emerg                         :omusrmsg:*

```

Then restart the service:

```
$ sudo systemctl restart rsyslog
```

### Update Logrotate

It also may be a good idea to check `logrotate` settings so the disk doesn't fill up:

```
$ sudo nano /etc/logrotate.conf
# see "man logrotate" for details

# global options do not affect preceding include directives

# rotate log files weekly
weekly

# keep 2 weeks worth of backlogs
rotate 2

# create new (empty) log files after rotating old ones
create

# use date as a suffix of the rotated file
#dateext

# uncomment this if you want your log files compressed
#compress

# packages drop log rotation information into this directory
include /etc/logrotate.d

# system-specific logs may also be configured here.
```

If any changes are made, restart the service:

```
$ sudo systemctl restart logrotate
```

## Configure Grafana Cloud

We will need a Grafana Cloud account to visualize the `promtail` data. 

Register here if you have not already, https://grafana.com/auth/sign-up/create-user?pg=login. 

In the grafana.com Grafana Cloud Portal, in the *philtel* secrion, in the *Grafana* box press the *Launch* button to launch the Grafana.net web interface.

In Grafana, use the left navigation to go to *Connections* --> *Add New Data Connection*. 

On the *Add New Connection* page, enter `loki` in the searchbox and in the results under the *Custom Data* header, press the button for *Hosted Logs*.

On the *Hosted Logs* page, enter the name of an API token you will be creating (`philtel-promtail-loki`) and press the *Create token* button.

This will generate sample `promtail` config, but because we already have our configuration file, we really only want this URL that contains are connection information. Copy this URL and paste it in place of the current one in ` /etc/promtail-syslog.yml`. 

Then, restart the service:

```
$ sudo systemctl restart promtail
```

Back in Grafana.net, use the left navigation to go to *Explore*. On this page you can query the logs as they are now being ingested into Loki.


### Configure Alerts

Grafana Cloud can alert us for specific events captured in our logs (or their absence). In this scenario, we will set up alerting if a device does not generate logs within the past hour, signifying it is down.
 
In Grafana, use the left navigation to go to *Alerts & IRM* --> *Alerting*. In the left navigation, navigate to *Contact points*. Click on the *Edit* icon to the left of `grafana-default-email`. On the resulting page, enter `metrics@philtel.org` into the `Addresses` field and press the *Save contact point* button.

In the left navigation, navigate to *Alert rules*. On the *Alert rules* page, press the button for *+ New alert rule*.

On the *New alert rule* page, in the *Enter alert rule name* section, enter a name for the device in the `Name` field. 

next, we will need a query to check for the absence of logs for a device over the last hour. We will use device `10.9.0.101` which is Mike's Test ATA. In the *Define query and alert condition* section, in the query builder, select `grafanacloud-philtel-logs` as the data source and use the following query for our device:

```
absent_over_time({hostname="10.9.0.101"} [1h])
```

In the *Set evaluation behavior* section, select `Alerting Rules` as the `Folder`. Press the button for *+New evaluation group* and in the resulting modal, enter `Uptime Evaluation Group` into the `Evaluation group name` field, and `1h` into the `Evaluation interval` field. Then press the *Create* button. Back in the *Set evaluation behavior* section, choose the newly created `Uptime Evaluation Group` option in the `Evaluation group` field. In the `Pending period` field, enter `1h5m`. Expand the heading for *Configure no data and error handling*. Select `OK` for the `Alert state if no data or all values are null` field and select `Error` for the `Alert state if execution error or timeout` field.

In the *Add annotations* section, enter `Mike Test - ATA Down` in the `Summary` field and `ATA "Mike Test" has not generated logs for 1h.` in the `Description` field.

Now press the button for *Save rule and exit*. The *Alert rules* page will now list the newly created rule. This rule will execute every hour and check to see if the device has generated logs. If it has not, it will send an email to the contact point.


## Sources

* <https://alexandre.deverteuil.net/post/syslog-relay-for-loki/>
* <https://forums.grandstream.com/t/gxw42xx-ht8xx-and-rsyslog-config-on-ubuntu-8-2102-0-2ubuntu1/52815>
* <https://grafana.com/docs/grafana/latest/alerting/alerting-rules/create-mimir-loki-managed-rule/>
* <https://promlabs.com/promql-cheat-sheet/>
* <https://thriftly.io/docs/components/Thriftly-Deployment-Beyond-the-Basics/Metrics-Prometheus/Creating-Receiving-Email-Alerts.html>