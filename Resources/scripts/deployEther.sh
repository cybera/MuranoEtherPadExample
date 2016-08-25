#!/bin/bash -v
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install gzip git curl python libssl-dev pkg-config build-essential -y
sudo apt-get install nodejs-legacy npm -y
cd /opt
git clone git://github.com/ether/etherpad-lite.git
cd etherpad-lite
sed -i 's/"port" : 9001/"port" : 80/' settings.json.template
bin/installDeps.sh > log.txt 2> error.txt
bin/run.sh --root >> log.txt 2>> error.txt &
