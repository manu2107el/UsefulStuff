#!/bin/bash

echo "Select a script to run:"
echo "1. Setup Web Server"
echo "2. Create new virtual host"
echo "3. Remove virtual host"
read -p "Enter your choice: " choice

case $choice in
  1) sh install.sh;;
  2) sh newhost.sh;;
  3) sh removehost.sh;;
  *) echo "Invalid option.";;
esac
