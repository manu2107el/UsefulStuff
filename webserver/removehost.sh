#!/bin/bash

# Prompt the user for the port number and virtual host name
read -p "Enter the virtual host name: " vhost

# Disable the virtual host
sudo a2dissite ${vhost}

# Create the virtual host configuration file
sudo rm /etc/apache2/sites-available/${vhost}.conf

# Remove Files
cd /var/www
tar czf ${vhost}.tar.gz ${vhost}
rm -r ${vhost}.tar.gz

# Restart Apache to apply the changes
sudo systemctl restart apache2