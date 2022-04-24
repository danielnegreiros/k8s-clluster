#!/bin/bash
sudo -i 

## Set Vagrant password and allow password ssh
echo "test123" | passwd --stdin vagrant
sed -i 's/#PasswordAuthentication/PasswordAuthentication/g' /etc/ssh/sshd_config
sudo systemctl restart sshd


