#!/bin/bash

read -p "Enter A zerotier ID (leave blank to skip) " zt
#Get zerotier
curl -s https://install.zerotier.com | sudo bash
zerotier-cli join $zt

#get netdata
sudo apt install netdata -y
sudo ufw allow 19999/tcp
sudo vim /etc/netdata/netdata.conf 

sudo apt-get update
sudo apt-get -y upgrade

# Install MySQL, Apache, and PHPMyAdmin
sudo apt-get install mysql-server apache2 libapache2-mod-php php-mysql phpmyadmin -y

# Enable the Apache rewrite module
sudo a2enmod rewrite

# Install the FTP server
sudo apt-get install vsftpd -y
sudo mv vsftpd.conf /etc/vsftpd.conf
sudo chown root:root /etc/vsftpd.conf

#user
sudo groupadd ftpusers
sudo adduser ftpuser
sudo usermod -d /var -m ftpuser
sudo usermod -a -G ftpusers ftpuser
sudo usermod -a -G www-data ftpuser
sudo chmod -R g+w /var/www
sudo chgrp -R www-data /var/www   
sudo find /var/www -type d -exec chmod 2775 {} \;
sudo find /var/www -type f -exec chmod ug+rw {} \;

# Restart to apply changes
service vsftpd restart
service apache2 restart

