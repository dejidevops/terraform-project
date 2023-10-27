#!/bin/bash
sudo apt update
sudo apt install apache2 -y
sudo cp index.html /var/www/html/index.html
sudo systemctl start apache
sudo systemctl enable apache2