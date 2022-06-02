# Testnet Monitoring Setup Guide

This guide is meant to complement the [Multi-Node Testnet Setup](/docs/Multi-Node-Testnet-Setup.md) guide.

- It is recommended Debian 11 is used for this host.
- Unless specified, all the commands shown should be run as `root`.

By the end of this guide, the following services will be set up:
- Grafana Dashboards
- PANIC Monitoring via Telegram
- Alert Manager via Matrix

## Requirements

- DNS: This guide will use `monitor.cosmostest.network` as an example. 
- Telegram: bot token and chat ID.
- Matrix: server address, token, rooms, and bot ID.

## Preparation

Upgrade the system.
```
apt update
apt dist-upgrade
```
### Set up IP Tables

Install the _iptables-persistent_ package. Say "Yes" to save the current IPv4 and IPv6 rules.
```
apt install iptables-persistent
```

Set up the following rule files.

`/etc/iptables/rules.v6`
```
*filter
:INPUT DROP [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -p tcp -m tcp --dport 22 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 443 -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
-A INPUT -p ipv6-icmp -j ACCEPT
COMMIT
```

`/etc/iptables/rules.v4`
```
*filter
:INPUT DROP [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -p tcp -m tcp --dport 22 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 443 -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
-A INPUT -p icmp -j ACCEPT
COMMIT
```

Apply the new rules.
```
iptables-restore rules.v4
ip6tables-restore rules.v6
```

## Set up Prometheus

Download Prometheus.
```
cd /opt
wget https://github.com/prometheus/prometheus/releases/download/v2.31.1/prometheus-2.31.1.linux-amd64.tar.gz
tar xf prometheus-2.31.1.linux-amd64.tar.gz
rm prometheus-2.31.1.linux-amd64.tar.gz
ln -s prometheus-2.31.1.linux-amd64 prometheus
mkdir prometheus/data
```

Create the `prometheus` user.
```
user=prometheus
adduser --system $user --no-create-home --group
chown -R $user:$user /opt/prometheus/
```

Create `/etc/systemd/system/prometheus.service`.
```
[Unit]
Description=Prometheus Metrics Server
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/opt/prometheus/prometheus \
--config.file /opt/prometheus/prometheus.yml \
--storage.tsdb.path /opt/prometheus/data/ --web.external-url http://localhost:9090/prometheus/ \
--storage.tsdb.retention.time 30d
ExecReload=/bin/kill -s HUP $MAINPID

[Install]
WantedBy=multi-user.target
```

Modify `/opt/prometheus/prometheus.yml` to configure the alert and scraping settings.
```
# my global config
global:
  scrape_interval: 15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
  # scrape_timeout is set to the global default (10s).

# Alertmanager configuration
alerting:
  alertmanagers:
  - scheme: http
    path_prefix: 'alertmanager/'
    static_configs:
    - targets:
      - localhost:9093

# Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
rule_files:
  - '/opt/alertmanager/rules/*.yml'
  # - "first_rules.yml"
  # - "second_rules.yml"

# Scrape configuration
scrape_configs:
  - job_name: 'node-exporters'
    scheme: http
    tls_config:
      insecure_skip_verify: true
    file_sd_configs:
    - files:
      - /opt/prometheus/hosts/*.json

  - job_name: 'internalhttp-mon'
    metrics_path: /probe
    params:
      module: [http_2xx]
    file_sd_configs:
    - files:
      - /opt/prometheus/blackbox-http/*.json
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: 127.0.0.1:9115  # The blackbox exporter's real hostname:port.

  - job_name: 'icmp-probe'
    metrics_path: /probe
    params:
      module: [icmp]
    file_sd_configs:
    - files:
      - /opt/prometheus/blackbox-icmp/*.json
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: 127.0.0.1:9115  # The blackbox exporter's real hostname:port.

```

Start the `prometheus` service.
```
systemctl daemon-reload
systemctl enable prometheus
systemctl start prometheus
```

## Set up Blackbox Exporter

Blackbox exporter monitors pings and http responses.

Download Blackbox Exporter.
```
cd /opt
wget https://github.com/prometheus/blackbox_exporter/releases/download/v0.19.0/blackbox_exporter-0.19.0.linux-amd64.tar.gz
tar xf blackbox_exporter-0.19.0.linux-amd64.tar.gz
rm blackbox_exporter-0.19.0.linux-amd64.tar.gz
ln -s blackbox_exporter-0.19.0.linux-amd64 blackbox_exporter
cd blackbox_exporter
```

Modify `blackbox_exporter/blackbox.yml`.
```
modules:
  http_2xx:
    prober: http
  http_post_2xx:
    prober: http
    http:
      method: POST
  tcp_connect:
    prober: tcp
  pop3s_banner:
    prober: tcp
    tcp:
      query_response:
      - expect: "^+OK"
      tls: true
      tls_config:
        insecure_skip_verify: false
  ssh_banner:
    prober: tcp
    tcp:
      query_response:
      - expect: "^SSH-2.0-"
  irc_banner:
    prober: tcp
    tcp:
      query_response:
      - send: "NICK prober"
      - send: "USER prober prober prober :prober"
      - expect: "PING :([^ ]+)"
        send: "PONG ${1}"
      - expect: "^:[^ ]+ 001"
  icmp:
    prober: icmp

  https_check:
    prober: http
    timeout: 15s
    http:
      valid_http_versions: ["HTTP/1.1", "HTTP/2"]
      method: GET
      # preferred_ip_protocol: ip4
      fail_if_ssl: false
      fail_if_not_ssl: true
      tls_config:
        insecure_skip_verify: false
  http_check:
    prober: http
    timeout: 5s
    http:
      valid_http_versions: ["HTTP/1.1", "HTTP/2"]
      method: GET
      # preferred_ip_protocol: ip4
      fail_if_ssl: false
      fail_if_not_ssl: false
      tls_config:
        insecure_skip_verify: true
```

Make the `prometheus` user the owner of the `black_box_exporter` folder.
```
chown -R prometheus:prometheus /opt/blackbox_exporter/
```

Add empty folders for HTTP and ICMP in the prometheus folder, the Ansible playbook will populate these.
```
mkdir /opt/prometheus/blackbox-http
mkdir /opt/prometheus/blackbox-icmp
```

Create `/etc/systemd/system/blackbox_exporter.service`.
```
[Unit]
Description=Blackbox Metrics Server
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/opt/blackbox_exporter/blackbox_exporter \
--config.file /opt/blackbox_exporter/blackbox.yml \

[Install]
WantedBy=multi-user.target
```

Start the `blackbox_exporter` service.
```
systemctl enable blackbox_exporter
systemctl start blackbox_exporter
```

## Set up Grafana

Install the Grafana package.
```
cd ~
wget https://dl.grafana.com/oss/release/grafana_8.2.3_amd64.deb
sudo dpkg -i grafana_8.2.3_amd64.deb
```

Start the Grafana service.
```
systemctl daemon-reload
systemctl enable grafana-server
systemctl start grafana-server
```

### Setup Nginx for TLS support

Install certbot and Nginx.
```
apt install certbot nginx
```

Get a Let's Encrypt certificate.
```
certbot certonly --webroot -w /var/www/html/ -d monitor.cosmostest.network --rsa-key-size 4096
```

Generate DH parameters.
```
openssl dhparam -writerand - 4096 > /etc/ssl/dhparam.pem
```

Enable certbot to reload Nginx on renewal. Add this line to `/etc/letsencrypt/cli.ini`:
```
deploy-hook = systemctl reload nginx
```

Configure Nginx to proxy to Grafana. Create `/etc/nginx/sites-available/monitor.cosmostest.network`:
```
server {
	listen 0.0.0.0:80;
	listen [::]:80;
	server_name monitor.cosmostest.network;
	location /.well-known {
		root /var/www/html;
	}
	location / {
		return 301 https://monitor.cosmostest.network$request_uri;
	}
}

server {
	listen 0.0.0.0:443 http2;
	listen [::]:443 http2;
	server_name monitor.cosmostest.network;

	ssl on;
	server_tokens off;
	ssl_protocols TLSv1.2 TLSv1.3;
	ssl_prefer_server_ciphers on;
	ssl_session_timeout 5m;
	ssl_session_cache builtin:1000 shared:SSL:10m;
	add_header Strict-Transport-Security "max-age=63072000;" always;
	add_header X-Content-Type-Options nosniff;
	add_header X-Frame-Options DENY;
	ssl_stapling on;
	ssl_stapling_verify on;
	ssl_trusted_certificate /etc/letsencrypt/live/monitor.cosmostest.network/fullchain.pem;
	ssl_ciphers 'ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES256-GCM-SHA384:AES128-GCM-SHA256:AES256-SHA256:AES128-SHA256:AES256-SHA:AES128-SHA:DES-CBC3-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!CAMELLIA:!DES:!MD5:!PSK:!RC4:!3DES';

	### SSL cert files ###
	ssl_dhparam          /etc/ssl/dhparam.pem;
	ssl_certificate      /etc/letsencrypt/live/monitor.cosmostest.network/fullchain.pem;
	ssl_certificate_key  /etc/letsencrypt/live/monitor.cosmostest.network/privkey.pem;

	### Add SSL specific settings here ###
	keepalive_timeout    60;

	location / {
		proxy_pass         http://127.0.0.1:3000;
		proxy_redirect     off;

		proxy_set_header   Host             $host;
		proxy_set_header   X-Real-IP        $remote_addr;
		proxy_set_header   X-Forwarded-For  $proxy_add_x_forwarded_for;
		proxy_max_temp_file_size 0;
		proxy_buffering off;

		client_max_body_size       8192M;
		proxy_read_timeout 1200;
	}
}
```

Enable `monitor.cosmostest.network` configuration.
```
ln -s /etc/nginx/sites-available/monitor.cosmostest.network /etc/nginx/sites-enabled/monitor.cosmostest.network
````

Reload nginx.
```
systemctl reload nginx
```

### Add Nodes to Monitor

Add a `.json` file in `/opt/prometheus/hosts/` for each node. Prometheus will automatically load the new config.

Example config for `/opt/prometheus/hosts/sync2.cosmostest.network.json`:
```
[
  {
    "targets": ["sync2.cosmostest.network:9100"],
    "labels": {
      "job": "cosmos-testnet",
      "environment": "sync2.cosmostest.network_exporter",
      "service": "sync2.cosmostest.network_exporter"
    }
  },
  {
    "targets": ["sync2.cosmostest.network:26660"],
    "labels": {
      "job": "cosmos-testnet_gaiad",
      "environment": "sync2.cosmostest.network_gaiad_exporter",
      "service": "sync2.cosmostest.network_gaiad_exporter"
    }
  }
]
```

### Configure Grafana Dashboards

Grafana is now available in this URL:
```
https://monitor.cosmostest.network/login
```

Log in and update the `admin` password when prompted.

To add the Prometheus data source:
1. Go to the Configuration menu (cog icon) and click _Data Sources_.
2. Click _Add Data Source_.
3. Select Prometheus.
4. In the URL field, enter `http://127.0.0.1:9090/prometheus` and save the data source.

Dashboard URLs:
- Node Exporter: https://grafana.com/grafana/dashboards/1860
- Blackbox Exporter: https://grafana.com/grafana/dashboards/7587
- Cosmos: https://grafana.com/grafana/dashboards/11036

To add dashboards:
1. Click the Dashboards menu (four square) and click _Import_.
2. Enter the dashboard URL.
3. Select Prometheus as the data source.
4. Save the dashboard.

## (Optional) Set Up Node Exporter Manually

Follow these steps to set up the node exporter service on additional nodes without using the Ansible playbook.

Node Exporter is set up on the host we want to monitor, not the monitor host.

Download Node Exporter.
```
cd /opt/
wget https://github.com/prometheus/node_exporter/releases/download/v1.2.2/node_exporter-1.2.2.linux-amd64.tar.gz
tar xf node_exporter-1.2.2.linux-amd64.tar.gz
rm node_exporter-1.2.2.linux-amd64.tar.gz
ln -s node_exporter-1.2.2.linux-amd64 node_exporter
cd node_exporter
```

Create the `node_exporter` user.
```
user=node_exporter
adduser --system $user --no-create-home --group
chown -R $user:$user /opt/node_exporter/
```

Create `/etc/systemd/system/node_exporter.service`.
```
[Unit]
Description=Node Exporter

[Service]
User=node_exporter
ExecStart=/opt/node_exporter/node_exporter --web.listen-address=[::]:9100 --collector.systemd --collector.textfile.directory="/opt/node_exporter/textfiles"

[Install]
WantedBy=multi-user.target
```

Create the folder Node Exporter will read textfiles from.
```
mkdir /opt/node_exporter/textfiles
```

Add a cronjob to log the size of the Gaia home folder every minute.
```
*/1 * * * * echo SIZE_FOLDER_GAIA{src=\"/home/gaia/.gaia/\"} $(du --max-depth=1 /home/gaia/.gaia/ | tail -n 1 | awk '{print $1}') > /opt/node_exporter/textfiles/SIZE_FOLDER_GAIA.prom
```

Start the Node Exporter service.
```
systemctl daemon-reload
systemctl enable node_exporter.service
systemctl start node_exporter.service
```

## Set up PANIC

Install the required packages.
```
sudo apt-get install python3-pip git libffi-dev redis adduser libfontconfig1
```

Create `panic` user and log in.

```
useradd -s /bin/bash -m panic
su panic
```

Install `pipenv`.
```
pip install pipenv
```

Clone the PANIC repo.
```
git clone https://github.com/SimplyVC/panic_cosmos.git
cd panic_cosmos
pipenv sync
```

### PANIC Configuration

Run the setup wizard.
```
pipenv run python run_setup.py
Welcome to the PANIC alerter!
==== General
The first step is to set a unique identifier for the alerter. This can be any word that uniquely describes the setup being monitored. Uniqueness is very important if you are running multiple instances of the PANIC alerter, to avoid any possible Redis clashes. The name will only be used internally and will not show up in alerts.
Please insert the unique identifier:
cosmos_testnet_panic

==== Alerts
By default, alerts are output to a log file and to the console. Let's set up the rest of the alerts.
---- Telegram Alerts
Alerts sent via Telegram are a fast and reliable means of alerting that we highly recommend setting up. This requires you to have a Telegram bot set up, which is a free and quick procedure.
Do you wish to set up Telegram alerts? (Y/n)
y
Please insert your Telegram bot's API token:
[Enter your token]
Successfully connected to Telegram bot.
Please insert the chat ID for Telegram alerts:
[Enter your chat ID]
Do you wish to test Telegram alerts now? (Y/n)
y
Test alert sent successfully.
Was the testing successful? (Y/n)
y
---- Email Alerts
Email alerts are more useful as a backup alerting channel rather than the main one, given that one is much more likely to notice a a message on Telegram or a phone call. Email alerts also require an SMTP server to be set up for the alerter to be able to send.
Do you wish to set up email alerts? (Y/n)
n
---- Twilio Alerts
Twilio phone-call alerts are the most important alerts since they are the best at grabbing your attention, especially when you're asleep! To set these up, you have to have a Twilio account set up, with a registered Twilio phone number and a verified phone number.The timed trial version of Twilio is free.
Do you wish to set up Twilio alerts? (Y/n)
n

==== Periodic alerts
---- Periodic alive reminder
The periodic alive reminder is a way for the alerter to inform its users that it is still running.
Do you wish to set up the periodic alive reminder? (Y/n)
y
Please enter the amount of seconds you want to pass for the periodic alive reminder. Make sure that you insert a positive integer.
300 
You will be reminded that the alerter is still running every 0h 5m 0s. Is this correct (Y/n) 
y
Would you like the periodic alive reminder to send alerts via Telegram? (Y/n)
y

==== Commands
---- Telegram Commands
Telegram is also used as a two-way interface with the alerter and as an assistant, allowing you to do things such as snooze phone call alerts and to get the alerter's current status from Telegram. Once again, this requires you to set up a Telegram bot, which is free and easy. You can reuse the Telegram bot set up for alerts.
NOTE: If you are running more than one instance of the PANIC alerter, do not use the same telegram bot as the other instance/s.
Do you wish to set up Telegram commands? (Y/n)
y
Please insert your Telegram bot's API token:
[Enter your token]
Successfully connected to Telegram bot.
Please insert the authorised chat ID:
[Enter your chat ID]
Do you wish to test Telegram commands now? (Y/n)
y
Go ahead and send /ping to the Telegram bot.
Press ENTER once you are done sending commands...
Stopping the Telegram bot...
Was the testing successful? (Y/n)
y

==== Redis
Redis is used by the alerter to persist data every now and then, so that it can continue where it left off if it is restarted. It is also used to be able to get the status of the alerter and to have some control over it, such as to snooze Twilio phone calls.
Do you wish to set up Redis? (Y/n)
y
Please insert the Redis host IP: (default: localhost)

Please insert the Redis host port: (default: 6379)

Please insert the Redis password:

Do you wish to test Redis now? (Y/n)
y
Test completed successfully.

Setup finished.
Saved config/user_config_main.ini

==== Nodes
To produce alerts, the alerter needs something to monitor! The list of nodes to be included in the monitoring will now be set up. This includes validators, sentries, and any full nodes that can be used as a data source to monitor from the network's perspective. You may include nodes from multiple networks in any order; PANIC will figure out which network they belong to when you run it. Node names must be unique!
Do you wish to set up the list of nodes? (Y/n)
y
Unique node name:
val1_cosmostestnet
Node's RPC url (typically http://NODE_IP:26657):
http://rpc.val1.cosmostest.network:26657
Trying to connect to endpoint
Success.
Is this node a validator? (Y/n)
y
Successfully added validator node.
Do you want to add another node? (Y/n)
y
Unique node name:
val2_cosmostestnet
Node's RPC url (typically http://NODE_IP:26657):
http://rpc.val2.cosmostest.network:26657
Trying to connect to endpoint
Success.
Is this node a validator? (Y/n)
y
Successfully added validator node.
Do you want to add another node? (Y/n)
y
Unique node name:
val3_cosmostestnet
Node's RPC url (typically http://NODE_IP:26657):
http://rpc.val3.cosmostest.network:26657
Trying to connect to endpoint
Success.
Is this node a validator? (Y/n)
y
Successfully added validator node.
Do you want to add another node? (Y/n)
y
Unique node name:
sen1_cosmostestnet
Node's RPC url (typically http://NODE_IP:26657):
http://rpc.sen1.cosmostest.network:26657
Trying to connect to endpoint
Success.
Is this node a validator? (Y/n)
n
Successfully added full node.
Do you want to add another node? (Y/n)
y
Unique node name:
sen2_cosmostestnet
Node's RPC url (typically http://NODE_IP:26657):
http://rpc.sen2.cosmostest.network:26657
Trying to connect to endpoint
Success.
Is this node a validator? (Y/n)
n
Successfully added full node.
Do you want to add another node? (Y/n)
y
Unique node name:
sync_cosmostestnet
Node's RPC url (typically http://NODE_IP:26657):
http://rpc.sync.cosmostest.network:26657
Trying to connect to endpoint
Success.
Is this node a validator? (Y/n)
n
Successfully added full node.
Do you want to add another node? (Y/n)
n
Saved config/user_config_nodes.ini

==== GitHub Repositories
The GitHub monitor alerts on new releases in repositories. The list of GitHub repositories to monitor will now be set up.
Do you wish to set up the list of repos? (Y/n)
n
Saved config/user_config_repos.ini

Setup completed!
```

Run PANIC.
```
pipenv sync
pipenv run python run_alerter.py
```

### Setup systemd

Create `~/panic_cosmos/start.sh`.
```
#!/bin/sh
cd /home/panic/panic_cosmos
pipenv sync
pipenv run python run_alerter.py
```

Create `/etc/systemd/system/panic-cosmos.service`.
```
[Unit]
Description=panic cosmos
After=network-online.target

[Service]
User=panic
WorkingDirectory=/home/panic/panic_cosmos
ExecStart=/home/panic/panic_cosmos/start.sh
Restart=always
RestartSec=3
LimitNOFILE=4096
Environment="PATH=/home/panic/.local/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games"

[Install]
WantedBy=multi-user.target

```

Start the PANIC service.
```
sudo systemctl daemon-reload
sudo systemctl enable panic-cosmos.service # starts on boot
sudo systemctl start panic-cosmos.service # start process
```

### Adding New Nodes

To add, update, and delete nodes it is recommended to use Ansible playbooks (see the [`configure-panic` role](https://github.com/hyphacoop/cosmos-ansible/tree/main/roles/configure-panic)) or `/usr/local/bin/config_panic_nodes.py` on the monitoring server.

To manually add new nodes to be monitored, open `~/panic_cosmos/config/user_config_nodes.ini` and add node blocks with incremental IDs (e.g. `node_3`):
```
[node_3]
node_name = full-node-03
node_rpc_url = http://node3.cosmostest.network:26657
node_is_validator = false
include_in_node_monitor = true
include_in_network_monitor = true

[node_4]
node_name = full-node-04
node_rpc_url = http://node4.cosmostest.network:26657
node_is_validator = false
include_in_node_monitor = true
include_in_network_monitor = true
```

After updating the config either manually or with the script you must restart PANIC with `systemctl restart panic-cosmos`.


## Set up Alertmanager

This will set up a monitoring bot on a [Matrix](https://matrix.org/) server channel.

Download Alertmanager
```
cd /opt
wget https://github.com/prometheus/alertmanager/releases/download/v0.23.0/alertmanager-0.23.0.linux-amd64.tar.gz
tar xf alertmanager-0.23.0.linux-amd64.tar.gz
rm alertmanager-0.23.0.linux-amd64.tar.gz
ln -s alertmanager-0.23.0.linux-amd64 alertmanager
cd alertmanager
```

Modify `/opt/alertmanager/alertmanager.yml` with your Matrix room and webhook secret.
```
global:
  resolve_timeout: 5m

route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 12h
  receiver: 'cosmos-monitoring-matrix'
receivers:
- name: 'cosmos-monitoring-matrix'
  webhook_configs:
     - url: 'http://localhost:3001/alerts?secret=ENTER YOUR SECRET HERE'
inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'dev', 'instance']

```

Create `/etc/systemd/system/alertmanager.service`.
```
[Unit]
Description=Alert Manager
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
WorkingDirectory=/opt/alertmanager
ExecStart=/opt/alertmanager/alertmanager \
  --config.file=/opt/alertmanager/alertmanager.yml --cluster.listen-address= --web.external-url http://localhost:9093/alertmanager/

[Install]
WantedBy=multi-user.target
```

Make `prometheus` the owner of the Alertmanager folder.
```
chown -R prometheus:prometheus /opt/alertmanager/
```

Start the Alertmanager service.
```
systemctl daemon-reload
systemctl enable alertmanager
systemctl start alertmanager
```

The rules for Alertmanager are stored in `/opt/alertmanager/rules/`.

### Set up Alertmanager for Matrix

Install nodejs.
```
url -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
apt update
apt install nodejs
```

Download Matrix-Alertmanager.
```
cd /opt
git clone https://github.com/jaywink/matrix-alertmanager.git
cd matrix-alertmanager
```

Create `/opt/matrix-alertmanager/run.sh` and enter your Matrix server settings.
```
#!/bin/sh
export APP_PORT=3001 \
APP_ALERTMANAGER_SECRET="YOUR ALERTMANAGER SECRET" \
MATRIX_HOMESERVER_URL="YOUR HOMESERVER" \
MATRIX_ROOMS="cosmos-monitoring-matrix/YOUR ROOM ID" \
MATRIX_TOKEN="YOUR TOKEN" \
MATRIX_USER="YOUR BOT ID"
node src/app.js
```

Make the script executable.
```
chmod +x /opt/matrix-alertmanager/run.sh
```

Create `/etc/systemd/system/matrix-alertmanager.service`.
```
[Unit]
Description=Matrix Alert Manager
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
WorkingDirectory=/opt/matrix-alertmanager/
ExecStart=/opt/matrix-alertmanager/run.sh
[Install]
WantedBy=multi-user.target
```

Install Matrix-Alertmanager.
```
cd /opt/matrix-alertmanager/src
npm install
```

Start the Matrix-Alertmanager service.
```
systemctl daemon-reload
systemctl enable matrix-alertmanager
systemctl start matrix-alertmanager
```
