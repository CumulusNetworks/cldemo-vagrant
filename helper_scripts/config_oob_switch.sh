#!/bin/bash

#This file is transferred to the Cumulus VX and executed to re-map interfaces
#Extra config COULD be added here but I would recommend against that to keep this file standard.
echo "#################################"
echo "   Running OOB switch config"
echo "#################################"
sudo su

echo -e "auto eth0" > /etc/network/interfaces
echo -e "iface eth0 inet dhcp\n" >> /etc/network/interfaces

####### Custom Stuff

# Config for OOB Switch
echo -e "% for i in range(1, 16):" >> /etc/network/interfaces
echo -e "auto swp\${i}" >> /etc/network/interfaces
echo -e "iface swp\${i}" >> /etc/network/interfaces
echo -e "% endfor\n" >> /etc/network/interfaces
echo -e "auto bridge" >> /etc/network/interfaces
echo -e "iface bridge" >> /etc/network/interfaces
echo -e "bridge-ports glob swp1-15" >> /etc/network/interfaces
echo -e "address 192.168.100.1/24" >> /etc/network/interfaces

#echo -e "bridge-stp on" >> /etc/network/interfaces

## Convenience code. This is normally done in ZTP.
echo "cumulus ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/10_cumulus
mkdir -p /home/cumulus/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCzH+R+UhjVicUtI0daNUcedYhfvgT1dbZXgY33Ibm4MOo+X84Iwuzirm3QFnYf2O3uyZjNyrA6fj9qFE7Ekul4bD6PCstQupXPwfPMjns2M7tkHsKnLYjNxWNql/rCUxoH2B6nPyztcRCass3lIc2clfXkCY9Jtf7kgC2e/dmchywPV5PrFqtlHgZUnyoPyWBH7OjPLVxYwtCJn96sFkrjaG9QDOeoeiNvcGlk4DJp/g9L4f2AaEq69x8+gBTFUqAFsD8ecO941cM8sa1167rsRPx7SK3270Ji5EUF3lZsgpaiIgMhtIB/7QNTkN9ZjQBazxxlNVN6WthF8okb7OSt" >> /home/cumulus/.ssh/authorized_keys
chmod 700 -R /home/cumulus/.ssh
chown cumulus:cumulus -R /home/cumulus/.ssh
echo "This is a fake license" > /etc/cumulus/.license.txt

ifreload -a

echo "#################################"
echo "   Finished "
echo "#################################"
