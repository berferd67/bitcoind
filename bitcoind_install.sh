#!/bin/sh

#########
# Bitcoind and c-lightning on Ubuntu 16.04.4 Server Script
# Author: Paul Guest <paul.guest@acadsol.co.uk>
# Version: v0.1, 2018-03-17
# Source: https://github.com/berferd67/bitcoind
#########

########
# Set Hostname
########

#Assign existing hostname to $HOSTNAME
HOSTNAME=$(cat /etc/hostname)

#Display existing hostname
echo "Existing hostname is $HOSTNAME"

#Ask for new domainname $DOMAIN
echo "Enter new domain name: "
read DOMAIN

#Ask for new hostname $NEWHOST
echo "Enter new hostname: "
read NEWHOST

#change hostname in /etc/hosts & /etc/hostname
sudo sed -i "s/$HOSTNAME/$NEWHOST/g" /etc/hosts
sudo sed -i "s/$HOSTNAME/$NEWHOST/g" /etc/hostname

#display new hostname
echo "Your new hostname is $NEWHOST"

########
# Update repos and install updates
########

sudo apt-get update
sudo apt-get upgrade
sudo apt-get dist-upgrade

#Install dev tools

sudo apt-get install -y autoconf automake build-essential git libtool libgmp-dev libsqlite3-dev python python3 net-tools libsodium-dev


#Install additional dependencies for development and testing

sudo apt-get install -y asciidoc valgrind python3-pip
sudo pip3 install python-bitcoinlib

########
#Configure Uncomplicated Firewall to allow access to ssh, bitcoind and lightningd
########

sudo ufw enable
sudo ufw allow 22
sudo ufw allow 8333
sudo ufw allow 9735


########
#Harden ssh server
########

#Install fail2ban which blocks repaeated login attempts (banned for 10 mins after 5 failed logins)
sudo apt-get install fail2ban

#Configure keys based authentication
ssh-keygen -t rsa
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_rsa
cat id_rsa.pub >> ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

##
#Comment out existing entries and append config to eof
##
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.ORIG
sudo echo "# Installation Script Hardening Entries" >> /etc/ssh/sshd_config

#Disable root logins
sudo sed -i "s/PermitRootLogin/#PermitRootLogin/g" /etc/ssh/sshd_config
sudo echo "PermitRootLogin no" >> /etc/ssh/sshd_config

#Allow certain users access
sudo sed -i "s/AllowUsers/#AllowUsers/g" /etc/ssh/sshd_config
sudo echo "AllowUsers paul" >> /etc/ssh/sshd_config

#Disable Protocol 1
sudo sed -i "s/Protocol/#Protocol/g" /etc/ssh/sshd_config
sudo echo "Protocol 2" >> /etc/ssh/sshd_config

#Disable password authentication forcing use of keys
sudo sed -i "s/PasswordAuthentication/#PasswordAuthentication/g" /etc/ssh/sshd_config
sudo echo "PasswordAuthentication no" >> /etc/ssh/sshd_config


########
#Install Bitcoin and Lightning
########

#Install Bitcoind

sudo apt-get install software-properties-common
sudo add-apt-repository ppa:bitcoin/bitcoin
sudo apt-get update
sudo apt-get install -y bitcoind


#Install Lightning

git clone https://github.com/ElementsProject/lightning.git
cd lightning
make


#Run bitcoind and lightningd

# bitcoind &
# ./lightningd/lightningd &
# ./cli/lightning-cli help
