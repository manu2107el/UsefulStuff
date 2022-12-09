#!/bin/bash
sudo apt update
sudo apt upgrade -y
sudo apt install docker.io -y
sudo apt-get update
sudo apt-get install docker-compose-plugin -y
sudo docker compose version
sudo docker-compose up -d