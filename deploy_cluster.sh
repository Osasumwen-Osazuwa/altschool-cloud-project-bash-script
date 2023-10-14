#!/bin/bash

# Create and provision 'Master' VM
echo "Creating and provisioning Master VM..."
vagrant init ubuntu/bionic64
vagrant up

# SSH into 'Master' VM and install LAMP stack
echo "Installing LAMP stack on Master VM..."
vagrant ssh -c "sudo apt-get update && sudo apt-get install -y apache2 mysql-server php libapache2-mod-php php-mysql"

# Create a test PHP page on 'Master' VM
echo "<?php phpinfo(); ?>" > test.php
vagrant scp test.php default:/var/www/html/

# Create and provision 'Slave' VM
echo "Creating and provisioning Slave VM..."
vagrant init ubuntu/bionic64
vagrant up

# SSH into 'Slave' VM and install LAMP stack
echo "Installing LAMP stack on Slave VM..."
vagrant ssh -c "sudo apt-get update && sudo apt-get install -y apache2 mysql-server php libapache2-mod-php php-mysql"

# Create a test PHP page on 'Slave' VM
echo "<?php phpinfo(); ?>" > test.php
vagrant scp test.php default:/var/www/html/

# Install and configure Nginx as the Load Balancer
echo "Installing and configuring Nginx as the load Balancer"
vagrant ssh master -c "sudo apt-get install -y nginx"
vagrant ssh master -c "sudo echo 'upstream backend {
  server 192.168.33.10; # IP of Master VM
  server 192.168.33.11; # IP of Slave VM
}
server {
  listen 80;
  location / {
    proxy_pass http://backend;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
  }
}' | sudo tee /etc/nginx/sites-available/loadbalancer.conf"

vagrant ssh master -c "sudo ln -s /etc/nginx/sites-available/load-balancer.conf /etc/nginx/sites-enabled/"
vagrant ssh master -c "sudo systemctl restart nginx"

# Provide instructions for testing
echo "Deployment complete. Access the LAMP stack through the Load Balancer at http://192.168.33.10"

