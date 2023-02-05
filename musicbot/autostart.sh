#!/bin/bash

echo "JMusic Bot Service Creation Script"

# Check if Java is installed
if command -v java > /dev/null; then
  echo -e "\033[32mJava is already installed.\033[0m"
else
  echo -e "\033[31mJava is not installed.\033[0m"
  read -p "Do you want to install Java now? [y/n]: " install_java
  if [ "$install_java" = "y" ]; then
    sudo apt-get update
    sudo apt-get install openjdk-8-jre-headless
  else
    echo "Exiting script..."
    exit 1
  fi
fi

# Ask for service name
read -p "Enter the name for the service: " service_name
if [ -z "$service_name" ]; then
  echo "Service name cannot be empty. Exiting script..."
  exit 1
fi
service_name="$service_name.service"

# Ask for description
read -p "Enter a description for the service: " description

# Ask for file paths
read -p "Enter the path to the JMusicBot files: " files_path
if [ -z "$files_path" ]; then
  echo "Files path cannot be empty. Exiting script..."
  exit 1
fi
read -p "Enter the name of the config file (with file extension): " config_file

read -p "Enter the name of the JMusicBot jar file (with file extension): " jar_file


# Ask for user and group
read -p "Enter the user the service will be executed as: " service_user
read -p "Enter the group the service will be executed as: " service_group

# Create the service file
echo -e "[Unit]\nDescription=$description\nAfter=network.target network-online.target\n\n[Service]\nExecStart=/usr/bin/java -Dnogui=true -Dconfig=$files_path/$config_file -jar $files_path/$jar_file\nType=simple\nUser=$service_user\nGroup=$service_group\nRestart=on-failure\nRestartSec=5\nStartLimitInterval=60s\nStartLimitBurst=3\n\n[Install]\nWantedBy=multi-user.target" > "/etc/systemd/system/$service_name"

# Reload system manager configuration
sudo systemctl daemon-reload

# Show preview of service file
echo "Preview of $service_name:"
cat "/etc/systemd/system/$service_name"

# Ask to enable and start the service
read -p "Do you want to enable and start the service now? [y/n]: " start_service
if [ "$start_service" = "y" ]; then
  sudo systemctl enable "$service_name"
  sudo systemctl start "$service_name"
  echo "Service enabled and started successfully."
else
  echo "Service was not enabled or started."
fi
