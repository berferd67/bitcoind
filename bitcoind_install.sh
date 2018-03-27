#!/bin/sh

#########
# Bitcoind and c-lightning on Ubuntu 16.04.4 Server Script
# Author: Paul Guest <paul.guest@acadsol.co.uk>
# Version: v0.1, 2018-03-17
# Source: https://github.com/berferd67/bitcoind
#########

########
# Check whether script is running as root
########

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

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

apt-get update && apt-get dist-upgrade && apt-get clean

#Install dev tools
#apt-get install -y autoconf automake build-essential git libtool libgmp-dev libsqlite3-dev python python3 net-tools libsodium-dev
yum install -y clang gmp-devel libsq3-devel net-tools libsodium-devel valgrind wget git asciidoc
sudo yum clean all

#Install Python3
sudo yum -y install https://centos7.iuscommunity.org/ius-release.rpm
sudo yum -y install python36u
sudo yum -y install python36u-pip
sudo yum -y install python36u-devel
sudo pip3.6 install python-bitcoinlib
sudo pip3.6 install --upgrade pip


#Add a user to be used for bitcoind and lightningd
echo "Enter username for new user: "
read NEWUSER
adduser $NEWUSER
echo "Enter new password for new user: "
read NEWPASSWORD
echo $NEWPASSWORD |passwd $NEWUSER --stdin

########
#Configure Uncomplicated Firewall to allow access to ssh, bitcoind and lightningd
########

firewall-cmd --add-port 22/tcp
firewall-cmd --add-port 22/tcp --permanent
firewall-cmd --add-port 8333/tcp
firewall-cmd --add-port 8333/tcp --permanent
firewall-cmd --add-port 9735/tcp
firewall-cmd --add-port 9735/tcp --permanent
#ufw enable
#ufw allow 22
#ufw allow 8333
#ufw allow 9735


########
#Harden ssh server
########

#Install fail2ban which blocks repeated login attempts (banned for 10 mins after 5 failed logins)
apt-get install fail2ban

#Configure keys based authentication
sudo -i -u $NEWUSER bash << EOF
cd ~/
ssh-keygen -t rsa
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_rsa
cat id_rsa.pub >> ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
EOF

#
#Comment out existing entries and append config to eof
#
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.ORIG
echo "########" >> /etc/ssh/sshd_config
echo "# Installation Script Hardening Entries" >> /etc/ssh/sshd_config
echo "########" >> /etc/ssh/sshd_config
echo " " >> /etc/ssh/sshd_config

#Disable root logins
sed -i "s/PermitRootLogin/#PermitRootLogin/g" /etc/ssh/sshd_config
echo "#Disable root logins" >> /etc/ssh/sshd_config
echo "PermitRootLogin no" >> /etc/ssh/sshd_config
echo " " >> /etc/ssh/sshd_config

#Allow certain users access
sed -i "s/AllowUsers/#AllowUsers/g" /etc/ssh/sshd_config
echo "#Allow certain users access" >> /etc/ssh/sshd_config
echo "AllowUsers paul" >> /etc/ssh/sshd_config
echo " " >> /etc/ssh/sshd_config

#Disable Protocol 1
sed -i "s/Protocol/#Protocol/g" /etc/ssh/sshd_config
echo "#Disable Protocol 1" >> /etc/ssh/sshd_config
echo "Protocol 2" >> /etc/ssh/sshd_config
echo " " >> /etc/ssh/sshd_config

#Disable password authentication forcing use of keys
sed -i "s/PasswordAuthentication/#PasswordAuthentication/g" /etc/ssh/sshd_config
echo "#Disable password authentication forcing use of keys" >> /etc/ssh/sshd_config
echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
echo " " >> /etc/ssh/sshd_config

#Display instructions to copy key to remote host
echo "########"
echo "Make sure you copy the key to a remote client BEFORE disabling password authentication"
echo "########"
echo "Use the following commands on a REMOTE client"
echo "Copy the secret key to local ssh directory"
echo "Don't f*ck this up or you'll lock yourself out"
echo "########"
echo "mkdir ~/.ssh "
echo "chmod 700 ~/.ssh"
echo "scp %user@%host:/%home/%user/.ssh/id_rsa ~/.ssh/"

#Wait for the user to respond
read -p "Hit Enter to continue once you've copied the key"

#Confirm remote access
echo "Confirm remote access before continuing"
echo "ssh %user@%host"
read -p "Hit Enter when you're sure you have key based access"

#restart ssh service
/etc/init.d/networking restart


########
#Install Bitcoin and Lightning
########

#Install Bitcoind
apt-get install software-properties-common
add-apt-repository ppa:bitcoin/bitcoin
apt-get update
apt-get install -y bitcoind

#Install Lightning
git clone https://github.com/ElementsProject/lightning.git
cd lightning
make

#Create crontab entries to start services at reboot
sudo -i -u $NEWUSER bash << EOF
echo "@reboot /usr/local/bin/bitcoind -daemon" >> /var/spool/cron/$NEWUSER
echo "@reboot /home/"$NEWUSER"/lightning/lightningd" >> /var/spool/cron/$NEWUSER
# ./lightningd/lightningd &
# ./cli/lightning-cli help
#EOF


#Run bitcoind and lightningd
#sudo -i -u $NEWUSER bash << EOF
# bitcoind &
# ./lightningd/lightningd &
# ./cli/lightning-cli help
#EOF
