#!/bin/bash

# Prompt the user for the port number and virtual host name
read -p "Enter the port number: " port
read -p "Enter the virtual host name: " vhost

# Create the virtual host configuration file
cat > /etc/apache2/sites-available/${vhost}.conf <<EOL
<VirtualHost *:${port}>
    ServerName ${vhost}
    DocumentRoot /var/www/html/${vhost}

    <Directory /var/www/html/${vhost}>
        AllowOverride All
    </Directory>
</VirtualHost>
EOL

# Enable the virtual host
a2ensite ${vhost}

# Restart Apache to apply the changes
systemctl restart apache2
