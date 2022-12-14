#!/bin/bash

# Prompt the user for the port number and virtual host name
read -p "Enter the port number: " port
read -p "Enter the virtual host name: " vhost

# Create the virtual host configuration file
cat > /etc/apache2/sites-available/${vhost}.conf <<EOL
Listen *:${port}
<VirtualHost *:${port}>
    ServerName ${vhost}
    DocumentRoot /var/www/${vhost}

    <Directory /var/www/${vhost}>
        AllowOverride All
    </Directory>
</VirtualHost>
EOL

# Enable the virtual host
sudo a2ensite ${vhost}

# Restart Apache to apply the changes
sudo systemctl restart apache2
