#!/bin/bash -v

## Install package dependencies
sudo apt-get update
## Upgrade would be nice but it adds a lot to the startup time to this application
#sudo apt-get upgrade -y
sudo apt-get install gzip git curl python libssl-dev pkg-config build-essential nodejs-legacy npm supervisor -y

## Fetch software, configure and install
cd /opt
git clone --branch 1.6.0 https://github.com/ether/etherpad-lite.git etherpad-lite
cd etherpad-lite
sed -i 's/"port" : 9001/"port" : 80/' settings.json.template
bin/installDeps.sh > log.txt 2> error.txt

## Setup supervisord to keep the service running
cat << EOT >> /etc/supervisor/conf.d/etherpad.conf
[program:etherpad]
command=/opt/etherpad-lite/bin/run.sh --root
autostart=true
autorestart=true
stderr_logfile=/var/log/etherpad.err.log
stdout_logfile=/var/log/etherpad.out.log
EOT

## Run
service supervisor restart
