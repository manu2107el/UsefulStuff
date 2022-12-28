#!/bin/bash

#Get zerotier
curl -s https://install.zerotier.com | sudo bash

#get netdata
sudo apt install netdata -y
sudo ufw allow 19999/tcp
sudo vim /etc/netdata/netdata.conf 

sudo apt-get update
sudo apt-get -y upgrade

#INSTALL
sudo apt install docker.io -y
git clone https://github.com/key-networks/ztncui-aio
cd ztncui-aio
docker pull keynetworks/ztncui
docker run -d -p9993:9993/udp -p3443:3443 -p3180:3180 \
    -v /mydata/ztncui:/opt/key-networks/ztncui/etc \
    -v /mydata/zt1:/var/lib/zerotier-one \
    --env-file ./denv \
    --name ztncui \
    keynetworks/ztncui