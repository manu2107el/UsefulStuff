#!/bin/bash

# Check for Java
if type -p java; then
    echo -e "\e[32mJava is installed\e[0m"
else
    echo -e "\e[31mJava is not installed\e[0m"
    read -p "Do you want to install Java now? (y/n): " install_java
    if [ "$install_java" == "y" ]; then
        sudo apt-get update
        sudo apt install -y openjdk-18-jdk
    fi
fi

# Check for screen
if type -p screen; then
    echo -e "\e[32mScreen is installed\e[0m"
else
    echo -e "\e[31mScreen is not installed\e[0m"
    read -p "Do you want to install Screen now? (y/n): " install_screen
    if [ "$install_screen" == "y" ]; then
        sudo apt-get update
        sudo apt-get install screen
    fi
fi
# Prompt user for Minecraft server username
read -p "Enter Minecraft server username: " user

# Prompt user for Minecraft server files directory
read -p "Enter the directory where the Minecraft server files are located: " server_dir

# Prompt user for service file name
read -p "Enter the name for the service file (without the .service extension): " service_name

# Prompt user for the amount of RAM to allocate to the server in GB
read -p "Enter the amount of RAM to allocate to the server in GB: " ram_gb

# Prompt user for screen name
read -p "Enter the screen name for the Minecraft server: " screen_name

# Prompt user for the jar file name
read -p "Enter the name for the jar file (with the .jar extension): " jar_file

# Create the service file
echo "[Unit]
Description=Minecraft Server
After=network.target

[Service]
User=$user
WorkingDirectory=$server_dir
ExecStart=/usr/bin/screen -DmS $screen_name -m /usr/bin/java -Xmx$((ram_gb * 1024))M -Xms$((ram_gb * 1024))M -jar $jar_file nogui
ExecStop=/usr/bin/screen -p 0 -S minecraft -X eval 'stuff "say SERVER SHUTTING DOWN. Saving map..."\015'
ExecStop=/usr/bin/screen -p 0 -S minecraft -X eval 'stuff "save-all"\015'
ExecStop=/usr/bin/screen -p 0 -S minecraft -X eval 'stuff "stop"\015'
ExecStop=/bin/sleep 3
Restart=on-failure

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/$service_name.service

# Reload the systemd configuration
systemctl daemon-reload

# Enable the service
systemctl enable $service_name

# Start the service
systemctl start $service_name

# Check the status of the service
systemctl status $service_name