#!/bin/bash

#This file is transferred to the Cumulus VX and executed to re-map interfaces
#Extra config COULD be added here but I would recommend against that to keep this file standard.
echo "#################################"
echo "   Running 2nd_device_config.sh"
echo "#################################"
sudo su

echo -e "auto eth0" > /etc/network/interfaces
echo -e "iface eth0 inet dhcp\n" >> /etc/network/interfaces

####### Custom Stuff

# Config for OOB Switch
echo -e "% for i in range(1, 15):" >> /etc/network/interfaces
echo -e "auto swp\${i}" >> /etc/network/interfaces
echo -e "iface swp\${i}" >> /etc/network/interfaces
echo -e "% endfor\n" >> /etc/network/interfaces
echo -e "auto bridge" >> /etc/network/interfaces
echo -e "iface bridge" >> /etc/network/interfaces
echo -e "bridge-ports glob swp1-13" >> /etc/network/interfaces
#echo -e "bridge-stp on" >> /etc/network/interfaces

ifreload -a

echo "#################################"
echo "   Finished "
echo "#################################"
