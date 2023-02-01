# Configuring Node Exporter

To capture metrics from a Linux server, we will install `node-exporter` and ingest data into `prometheus`.

## Installation

Download the latests `node-exporter` version and extract it:

```
$ cd ~
$ wget https://github.com/prometheus/node_exporter/releases/download/v1.5.0/node_exporter-1.5.0.linux-amd64.tar.gz
$ tar -xzf node*
$ rm *.tar.gz
```


Create the `node_exporter` user, move the new files, and change ownership of them to this user:

```
$ sudo groupadd --system node_exporter
$ sudo useradd -s /sbin/nologin --system -g node_exporter node_exporter
$ sudo mv node_exporter*/* /usr/local/bin
$ sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter
$ rm -rf ./node_exporter-*
```

Next, we will create a `systemd` service:

```
$ sudo nano /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
```

Then start and enable the service"

```
$ sudo systemctl daemon-reload
$ sudo systemctl enable --now node_exporter
```

## Adding Server Metrics to Prometheus

Modify the `prometheus` configuration file and make sure that the router we want to monitor is in the `targets` list:

```
$ sudo nano /etc/prometheus/prometheus.yml
...
- job_name: 'node'
   scrape_interval: 5s
   static_configs:
     - targets: ['127.0.0.1:9100']
```

Now validate the configuration and restart `prometheus`:

```
$ promtool check config /etc/prometheus/prometheus.yml
Checking /etc/prometheus/prometheus.yml
 SUCCESS: /etc/prometheus/prometheus.yml is valid prometheus config file syntax
$ sudo systemctl restart prometheus
```

## Configure Grafana Cloud

In Grafana, use the left navigation to go to *Dashboard* --> *Import*. 

On the *Import Dashboard* page, enter `https://grafana.com/grafana/dashboards/1860-node-exporter-full/` in the *Import via grafana.com* field and press the button for *Load*.

After loading the dashboard, be sure to select `grafanacloud-philtel-prom` under the *Prometheus* dropdown and press the *Import* button.

The dashboard will now load automatically.

## Sources

* <https://ourcodeworld.com/articles/read/1686/how-to-install-prometheus-node-exporter-on-ubuntu-2004>