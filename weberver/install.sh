#!/bin/bash

# Update package index
sudo apt-get update

# Install Apache, PHP, MySQL, and FileZilla
sudo apt-get install apache2 php mysql-server filezilla

# Install PHPMyAdmin
sudo apt-get install phpmyadmin

# Move PHPMyAdmin to a different port
sudo nano /etc/phpmyadmin/apache.conf

# Edit the Listen directive to specify the new port for PHPMyAdmin
# For example, to use port 8080, change the line to:
# Listen 8080

# Restart Apache to apply the changes
sudo service apache2 restart

# Update the files in the Apache directory
# Replace /path/to/local/directory with the path to the directory on your local machine
# and username@hostname with the username and hostname of your server
# For example, if your username is "user" and the hostname of your server is "myserver",
# the command would be:
# filezilla user@myserver

# Connect to your server using FileZilla, and navigate to the Apache directory
# Use the FileZilla interface to upload the files you want to update.
