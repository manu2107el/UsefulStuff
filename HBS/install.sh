#!/bin/bash

curl -s https://install.zerotier.com | sudo bash
zerotier-cli join da558169b63ccb91
sudo apt install netdata -y
sudo ufw allow 19999/tcp
sudo vim /etc/netdata/netdata.conf 