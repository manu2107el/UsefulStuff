#!/bin/bash

#Get zerotier
curl -s https://install.zerotier.com | sudo bash

#get netdata
sudo apt install netdata -y
sudo ufw allow 19999/tcp
sudo vim /etc/netdata/netdata.conf 

sudo apt-get update
sudo apt-get -y upgrade


#instaLL
sudo apt install docker.io -y
sudo apt-get update
sudo apt-get install docker-compose -y
sudo docker-compose version
sudo docker-compose up -d