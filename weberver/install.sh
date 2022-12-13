#!/bin/bash
curl -s https://install.zerotier.com | sudo bash
zerotier-cli join da558169b66e7804

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
#sudo mv vsftpd.conf /etc/vsftpd.conf
sudo groupadd ftpusers

# add Apache user to FTP user group
sudo usermod -a -G ftpusers www-data

# set the Apache root directory as the home directory for FTP users
sudo sed -i 's/local_root=\/var\/www/local_root=\/var\/www\/html/' /etc/vsftpd.conf

# allow FTP users to write to the Apache root directory
sudo sed -i 's/write_enable=NO/write_enable=YES/' /etc/vsftpd.conf
#user
sudo adduser ftpusers
#sudo usermod -d /var/www -m ftpusers
#sudo usermod -a -G www-data ftpusers
#sudo chgrp -R www-data /var/www
#sudo chmod -R g+w /var/www
# Restart to apply changes
service vsftpd restart
service apache2 restart

