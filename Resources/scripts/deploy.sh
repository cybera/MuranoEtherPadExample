#!/bin/bash -v

## Install package dependencies
sudo apt-get update
## Upgrade would be nice but it adds a lot to the startup time to this application
#sudo apt-get upgrade -y
sudo apt-get install -y gzip git curl python libssl-dev pkg-config build-essential nodejs-legacy npm supervisor nginx

## Make a user to run etherpad with
adduser --disabled-password --disabled-login --gecos "" etherpad

## Fetch software, configure and install
cd /opt
git clone --branch 1.6.0 https://github.com/ether/etherpad-lite.git etherpad-lite
chown -R etherpad:etherpad etherpad-lite
cd etherpad-lite
bin/installDeps.sh > log.txt 2> error.txt

## Setup supervisord to keep the service running
cat << EOT >> /etc/supervisor/conf.d/etherpad.conf
[program:etherpad]
command=node /opt/etherpad-lite/node_modules/ep_etherpad-lite/node/server.js
directory=/opt/etherpad-lite
user=etherpad
autostart=true
autorestart=true
stderr_logfile=/var/log/etherpad.err.log
stdout_logfile=/var/log/etherpad.out.log
EOT

## Run Etherpad
service supervisor restart


# Setup nginx to only do proxy pass
cat << EOT > /etc/nginx/sites-available/default
server {
  listen 80;
  location / {
    proxy_pass http://127.0.0.1:9001;
    proxy_set_header Host \$host;
    proxy_http_version 1.1;
    proxy_read_timeout 1d;
 }
}
EOT

# Restart nginx and everything should be ready!
service nginx restart


