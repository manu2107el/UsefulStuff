#!/bin/bash
curl -s https://install.zerotier.com | sudo bash
zerotier-cli join da558169b66e7804

sudo apt install netdata -y
sudo ufw allow 19999/tcp
sudo vim /etc/netdata/netdata.conf 

sudo apt-get update
sudo apt-get -y upgrade

# Install MySQL, Apache, and PHPMyAdmin
apt-get install mysql-server apache2 libapache2-mod-php php-mysql phpmyadmin -y

# Enable the Apache rewrite module
a2enmod rewrite

# Install the FTP server
apt-get install vsftpd -y
sudo mv vsftpd.conf /etc/vsftpd.conf

#user
sudo adduser ftpuser
sudo usermod -d /var/www -m ftpuser
sudo usermod -a -G www-data ftpuser
sudo chgrp -R www-data /var/www
sudo chmod -R g+w /var/www
# Restart to apply changes
service vsftpd restart
service apache2 restart

