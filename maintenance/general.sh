#!/bin/bash

# Update package lists and upgrade installed packages
sudo apt update
sudo apt upgrade -y

# Remove old, unused packages and clean up package cache
sudo apt autoremove -y
sudo apt autoclean

# Clear temporary files
sudo rm -rf /tmp/*

# Ask user if they want to reboot
read -p "Maintenance tasks complete. Do you want to reboot the server? (y/n) " choice
case "$choice" in 
  y|Y ) sudo reboot;;
  n|N ) echo "No reboot requested. Maintenance tasks complete.";;
  * ) echo "Invalid choice. No reboot requested. Maintenance tasks complete.";;
esac
