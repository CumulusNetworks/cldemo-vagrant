#!/bin/bash

#This file is transferred to a Debian/Ubuntu Host and executed to re-map interfaces
#Extra config COULD be added here but I would recommend against that to keep this file standard.
echo "#################################"
echo "  Running OOB server config"
echo "#################################"
sudo su

#Replace existing network interfaces file
echo -e "auto lo" > /etc/network/interfaces
echo -e "iface lo inet loopback\n\n" >> /etc/network/interfaces
echo -e  "source /etc/network/interfaces.d/*.cfg\n" >> /etc/network/interfaces

#Add vagrant interface
echo -e "\n\nauto eth0" >> /etc/network/interfaces
echo -e "iface eth0 inet dhcp\n\n" >> /etc/network/interfaces

####### Custom Stuff
echo "auto eth1" >> /etc/network/interfaces
echo "iface eth1 inet static" >> /etc/network/interfaces
echo "    address 192.168.100.254" >> /etc/network/interfaces
echo "    netmask 255.255.255.0" >> /etc/network/interfaces

echo "cumulus ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/10_cumulus


ifup eth1
sed "s/PasswordAuthentication no/PasswordAuthentication yes/" -i /etc/ssh/sshd_config
service ssh restart



echo "#################################"
echo "   Finished"
echo "#################################"
