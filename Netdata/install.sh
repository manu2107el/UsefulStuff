#!/bin/bash

curl -s https://packagecloud.io/install/repositories/netdata/netdata-repoconfig/script.deb.sh
sudo bash
exit
sudo apt install netdata -y
sudo ufw allow 19999/tcp
sudo vim /etc/netdata/netdata.conf 