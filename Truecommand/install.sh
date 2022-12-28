#!/bin/bash

#Get zerotier
curl -s https://install.zerotier.com | sudo bash

#get netdata
sudo apt install netdata -y
sudo ufw allow 19999/tcp
sudo vim /etc/netdata/netdata.conf 

sudo apt-get update
sudo apt-get -y upgrade

#get depancencies
sudo apt-get install wget

#get Truecommand server
wget https://raw.githubusercontent.com/iXsystems/truecommand-install/main/debian/setup.sh -O - | sudo bash