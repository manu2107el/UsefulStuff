#!/bin/bash

# Update package index
apt-get update

# Install MySQL, Apache, and PHPMyAdmin
apt-get install mysql-server apache2 libapache2-mod-php php-mysql phpmyadmin -y

# Enable the Apache rewrite module
a2enmod rewrite

# Restart Apache to apply changes
service apache2 restart

# Install the FTP server
apt-get install vsftpd -y

# Open the FTP server configuration file in a text editor
nano /etc/vsftpd.conf

# Uncomment the following lines in the configuration file to enable FTP access to the Apache directory
# local_enable=YES
# write_enable=YES
# chroot_local_user=YES

# Restart the FTP server to apply changes
service vsftpd restart
