#!/bin/bash

#Get zerotier
curl -s https://install.zerotier.com | sudo bash

read -p "Enter a Zerotier network-ID to join" ztid

sudo zerotier-cli join $ztid


#instaLL
sudo apt install docker.io -y
sudo apt-get update
sudo apt-get install docker-compose -y
sudo docker-compose version
sudo docker-compose up -d