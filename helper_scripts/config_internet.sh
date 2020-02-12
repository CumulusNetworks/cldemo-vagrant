#!/bin/bash

#This file is transferred to the Cumulus VX and executed to re-map interfaces
#Extra config COULD be added here but I would recommend against that to keep this file standard.
echo "#################################"
echo "   Running config_internet.sh"
echo "#################################"
sudo su

echo -e "auto swp48" > /etc/network/interfaces
echo -e "iface swp48 inet dhcp\n" >> /etc/network/interfaces

####### Custom Stuff

# Config for OOB Switch
echo -e "auto eth0" >> /etc/network/interfaces
echo -e "iface eth0" >> /etc/network/interfaces
echo -e "    address 192.168.0.253/24" >> /etc/network/interfaces


# Exit 1
echo -e "auto swp1" >> /etc/network/interfaces
echo -e "iface swp1" >> /etc/network/interfaces


# Exit 2
echo -e "auto swp2" >> /etc/network/interfaces
echo -e "iface swp2" >> /etc/network/interfaces


# Setup SSH key authentication for Ansible
echo " #### Installing SSH Keys ####"
mkdir -p /home/cumulus/.ssh
#wget -O /home/cumulus/.ssh/authorized_keys http://192.168.0.254/authorized_keys
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCzH+R+UhjVicUtI0daNUcedYhfvgT1dbZXgY33Ibm4MOo+X84Iwuzirm3QFnYf2O3uyZjNyrA6fj9qFE7Ekul4bD6PCstQupXPwfPMjns2M7tkHsKnLYjNxWNql/rCUxoH2B6nPyztcRCass3lIc2clfXkCY9Jtf7kgC2e/dmchywPV5PrFqtlHgZUnyoPyWBH7OjPLVxYwtCJn96sFkrjaG9QDOeoeiNvcGlk4DJp/g9L4f2AaEq69x8+gBTFUqAFsD8ecO941cM8sa1167rsRPx7SK3270Ji5EUF3lZsgpaiIgMhtIB/7QNTkN9ZjQBazxxlNVN6WthF8okb7OSt" >> /home/cumulus/.ssh/authorized_keys
chmod 700 -R /home/cumulus/.ssh
chown cumulus:cumulus -R /home/cumulus/.ssh
echo "cumulus ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/10_cumulus
echo "#################################"
echo "   Finished "
echo "#################################"
