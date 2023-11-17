# Configuring a Prometheus Server

To capture metrics from our hardware, we will set up a Prometheus server.

## Installation

Create the `prometheus` user and some supporting directories:
```
$ sudo groupadd --system prometheus
$ sudo useradd -s /sbin/nologin --system -g prometheus prometheus
$ sudo mkdir /var/lib/prometheus
```

Download the latests `prometheus` version and extract it:

```
$ cd ~
$ wget https://github.com/prometheus/prometheus/releases/download/v2.37.5/prometheus-2.37.5.linux-amd64.tar.gz
$ tar -xzf prometheus*
$ rm *.tar.gz
```

Now move the files and change ownership of our directories to the `prometheus` user:

```
sudo mv prometheus* /etc/prometheus
sudo chown prometheus:prometheus /etc/prometheus
sudo chown prometheus:prometheus /var/lib/prometheus
sudo chown -R prometheus:prometheus /etc/prometheus/consoles
sudo chown -R prometheus:prometheus /etc/prometheus/console_libraries
```

Now let's move some binaries into `/usr/local/bin`:

```
sudo cp /etc/prometheus/prometheus /usr/local/bin/
sudo cp /etc/prometheus/promtool /usr/local/bin/
```

Next, we will create a `systemd` service:

```
$ sudo nano /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
Documentation=https://prometheus.io/docs/introduction/overview/
Wants=network-online.target
After=network-online.target
[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
--config.file /etc/prometheus/prometheus.yml \
--storage.tsdb.path /var/lib/prometheus/ \
--web.console.templates=/etc/prometheus/consoles \
--web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
```

Then start and enable the service:

```
$ sudo systemctl daemon-reload
$ sudo systemctl enable --now prometheus
```

## Adding Device Metrics

Now that we have the server set up, we can link in metrics from one of our routers.

Modify the `prometheus` configuration file and make sure that the router we want to monitor is in the `targets` list:

```
$ sudo nano /etc/prometheus/prometheus.yml
...
- job_name: 'openwrt_miketest'
   scrape_interval: 5s
   static_configs:
     - targets: ['10.8.0.101:9100']
```

Now validate the configuration and restart `prometheus`:

```
$ promtool check config /etc/prometheus/prometheus.yml
Checking /etc/prometheus/prometheus.yml
 SUCCESS: /etc/prometheus/prometheus.yml is valid prometheus config file syntax
$ sudo systemctl restart prometheus
```

## Configure Grafana Cloud

We will need a Grafana Cloud account to visualize the `prometheus` data. 

Register here, https://grafana.com/auth/sign-up/create-user?pg=login. 

After logging in, navigate to *SECURITY* --> *API Keys* and press the button for *+ Add API Key*.

In the popup, give the key an *API Key Name* like `philtel_prometheus` and set the *Role* to `MetricsPublisher` before pressing the *Create API Key* button

In the next popup you will get the API key. Save this key as it will not be displayed again.

Now, navigate to *GRAFANA CLOUD* --> *Philtel*. In the box for *Prometheus*, press the button for *Send Metrics*. This will open a page providing a block of config to be added to the `promethrus* configuration file. 

Edit the prometheus configuration file again and add this block in the bottom, be sure to replace `yourapikeyhere` with the API key you saved earlier:

```
$ sudo nano /etc/prometheus/prometheus.yml
# my global config
global:
  scrape_interval: 15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
  # scrape_timeout is set to the global default (10s).

# Alertmanager configuration
alerting:
  alertmanagers:
    - static_configs:
        - targets:
          # - alertmanager:9093

# Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  - job_name: "prometheus"

    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.

    static_configs:
      - targets: ["localhost:9090"]

  - job_name: 'openwrt_miketest'
    scrape_interval: 60s
    static_configs:
      - targets: ['10.9.0.101:9100']
  - job_name: 'openwrt_ttm01'
    scrape_interval: 12h
    static_configs:
      - targets: ['10.9.0.151:9100']
  - job_name: 'openwrt_iffy'
    scrape_interval: 60s
    static_configs:
      - targets: ['10.8.0.2:9100']
  - job_name: 'philtel-server'
    scrape_interval: 60s
    static_configs:
      - targets: ['127.0.0.1:9100']
remote_write:
  - url: https://prometheus-us-central1.grafana.net/api/prom/push
    basic_auth:
      username: "82312"
      password: "yourapikeyhere"
```

Now restart the `promethrus` service:

```
$ sudo systemctl restart prometheus
```

Back in the browser on the *philtel* page, in the *Grafana* box press the *Launch* button to launch the Grafana web interface.

In Grafana, use the left navigation to go to *Dashboard* --> *Import*. 

On the *Import Dashboard* page, enter `https://grafana.com/grafana/dashboards/11147-openwrt/` in the *Import via grafana.com* field and press the button for *Load*.

After loading the dashboard, be sure to select `grafanacloud-philtel-prom` under the *Prometheus* dropdown and press the *Import* button.

The dashboard will now load automatically.

## Sources

* <https://www.how2shout.com/linux/how-to-install-prometheus-in-debian-11-or-ubuntu-20-04/>
* <https://dev.to/kaitoii11/remote-writing-your-prometheus-metrics-to-grafana-cloud-3k24>