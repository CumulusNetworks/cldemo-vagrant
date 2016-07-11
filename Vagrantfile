# Created by Topology-Converter v4.1.0
#    using topology data from: topology.dot
#    NOTE: in order to use this Vagrantfile you will need:
#       -Vagrant(v1.7+) installed: http://www.vagrantup.com/downloads
#       -Cumulus Plugin for Vagrant installed: $ vagrant plugin install vagrant-cumulus
#       -the "helper_scripts" directory that comes packaged with topology-converter.py
#       -Virtualbox installed: https://www.virtualbox.org/wiki/Downloads

raise "vagrant-cumulus plugin must be installed, try $ vagrant plugin install vagrant-cumulus" unless Vagrant.has_plugin? "vagrant-cumulus"

$script = <<-SCRIPT
if grep -q -i 'cumulus' /etc/lsb-release &> /dev/null; then
    echo "### RUNNING CUMULUS EXTRA CONFIG ###"
    source /etc/lsb-release
    if [[ $DISTRIB_RELEASE =~ ^2.* ]]; then
        echo "  INFO: Detected a 2.5.x Based Release"
        echo "  adding fake cl-acltool..."
        echo -e "#!/bin/bash\nexit 0" > /bin/cl-acltool
        chmod 755 /bin/cl-acltool

        echo "  adding fake cl-license..."
        cat > /bin/cl-license <<'EOF'
#! /bin/bash
#-------------------------------------------------------------------------------
#
# Copyright 2013 Cumulus Networks, Inc.  All rights reserved
#

URL_RE='^http://.*/.*'

#Legacy symlink
if echo "$0" | grep -q "cl-license-install$"; then
    exec cl-license -i $*
fi

LIC_DIR="/etc/cumulus"
PERSIST_LIC_DIR="/mnt/persist/etc/cumulus"

#Print current license, if any.
if [ -z "$1" ]; then
    if [ ! -f "$LIC_DIR/.license.txt" ]; then
        echo "No license installed!" >&2
        exit 20
    fi
    cat "$LIC_DIR/.license.txt"
    exit 0
fi

#Must be root beyond this point
if (( EUID != 0 )); then
   echo "You must have root privileges to run this command." 1>&2
   exit 100
fi

#Delete license
if [ x"$1" == "x-d" ]; then
    rm -f "$LIC_DIR/.license.txt"
    rm -f "$PERSIST_LIC_DIR/.license.txt"

    echo License file uninstalled.
    exit 0
fi

function usage {
    echo "Usage: $0 (-i (license_file | URL) | -d)" >&2
    echo "    -i  Install a license, via stdin, file, or URL." >&2
    echo "    -d  Delete the current installed license." >&2
    echo >&2
    echo " cl-license prints, installs or deletes a license on this switch." >&2
}

if [ x"$1" != 'x-i' ]; then
    usage
    exit 100
fi
shift
if [ ! -f "$1" ]; then
    if [ -n "$1" ]; then
        if ! echo "$1" | grep -q "$URL_RE"; then
            usage
            echo "file $1 not found or not readable." >&2
            exit 100
        fi
    fi
fi

function clean_tmp {
    rm $1
}

if [ -z "$1" ]; then
    LIC_FILE=`mktemp lic.XXXXXX`
    trap "clean_tmp $LIC_FILE" EXIT
    echo "Paste license text here, then hit ctrl-d" >&2
    cat >$LIC_FILE
else
    if echo "$1" | grep -q "$URL_RE"; then
        LIC_FILE=`mktemp lic.XXXXXX`
        trap "clean_tmp $LIC_FILE" EXIT
        if ! wget "$1" -O $LIC_FILE; then
            echo "Couldn't download $1 via HTTP!" >&2
            exit 10
        fi
    else
        LIC_FILE="$1"
    fi
fi

/usr/sbin/switchd -lic "$LIC_FILE"
SWITCHD_RETCODE=$?
if [ $SWITCHD_RETCODE -eq 99 ]; then
    more /usr/share/cumulus/EULA.txt
    echo "I (on behalf of the entity who will be using the software) accept"
    read -p "and agree to the EULA  (yes/no): "
    if [ "$REPLY" != "yes" -a "$REPLY" != "y" ]; then
        echo EULA not agreed to, aborting. >&2
        exit 2
    fi
elif [ $SWITCHD_RETCODE -ne 0 ]; then
    echo '******************************' >&2
    echo ERROR: License file not valid. >&2
    echo ERROR: No license installed. >&2
    echo '******************************' >&2
    exit 1
fi

mkdir -p "$LIC_DIR"
cp "$LIC_FILE" "$LIC_DIR/.license.txt"
chmod 644 "$LIC_DIR/.license.txt"

mkdir -p "$PERSIST_LIC_DIR"
cp "$LIC_FILE" "$PERSIST_LIC_DIR/.license.txt"
chmod 644 "$PERSIST_LIC_DIR/.license.txt"

echo License file installed.
echo Reboot to enable functionality.
EOF
        chmod 755 /bin/cl-license

        echo "  Disabling default remap on Cumulus VX..."
        mv -v /etc/init.d/rename_eth_swp /etc/init.d/rename_eth_swp.backup

        echo "  Replacing fake switchd"
        rm -rf /usr/bin/switchd
        cat > /usr/sbin/switchd <<'EOF'
#!/bin/bash
PIDFILE=$1
LICENSE_FILE=/etc/cumulus/.license
RC=0

# Make sure we weren't invoked with "-lic"
if [ "$PIDFILE" == "-lic" ]; then
  if [ "$2" != "" ]; then
        LICENSE_FILE=$2
  fi
  if [ ! -e $LICENSE_FILE ]; then
    echo "No license file." >&2
    RC=1
  fi
  RC=0
else
  tail -f /dev/null & CPID=$!
  echo -n $CPID > $PIDFILE
  wait $CPID
fi

exit $RC
EOF
        chmod 755 /usr/sbin/switchd

        cat > /etc/init.d/switchd <<'EOF'
#! /bin/bash
### BEGIN INIT INFO
# Provides:          switchd
# Required-Start:
# Required-Stop:
# Should-Start:
# Should-Stop:
# X-Start-Before
# Default-Start:     S
# Default-Stop:
# Short-Description: Controls fake switchd process
### END INIT INFO

# Author: Kristian Van Der Vliet <kristian@cumulusnetworks.com>
#
# Please remove the "Author" lines above and replace them
# with your own name if you copy and modify this script.

PATH=/sbin:/bin:/usr/bin

NAME=switchd
SCRIPTNAME=/etc/init.d/$NAME
PIDFILE=/var/run/switchd.pid

. /lib/init/vars.sh
. /lib/lsb/init-functions

do_start() {
  echo "[ ok ] Starting Cumulus Networks switch chip daemon: switchd"
  /usr/sbin/switchd $PIDFILE 2>/dev/null &
}

do_stop() {
  if [ -e $PIDFILE ];then
    kill -TERM $(cat $PIDFILE)
    rm $PIDFILE
  fi
}

do_status() {
  if [ -e $PIDFILE ];then
    echo "[ ok ] switchd is running."
  else
    echo "[FAIL] switchd is not running ... failed!" >&2
    exit 3
  fi
}

case "$1" in
  start|"")
	log_action_begin_msg "Starting switchd"
	do_start
	log_action_end_msg 0
	;;
  stop)
  log_action_begin_msg "Stopping switchd"
  do_stop
  log_action_end_msg 0
  ;;
  status)
  do_status
  ;;
  restart)
	log_action_begin_msg "Re-starting switchd"
  do_stop
	do_start
	log_action_end_msg 0
	;;
  reload|force-reload)
	echo "Error: argument '$1' not supported" >&2
	exit 3
	;;
  *)
	echo "Usage: $SCRIPTNAME [start|stop|restart|status]" >&2
	exit 3
	;;
esac

:
EOF
        chmod 755 /etc/init.d/switchd
        reboot

    elif [[ $DISTRIB_RELEASE =~ ^3.* ]]; then
        echo "  INFO: Detected a 3.x Based Release"

        echo "  Disabling default remap on Cumulus VX..."
        mv -v /etc/hw_init.d/S10rename_eth_swp.sh /etc/S10rename_eth_swp.sh.backup
        reboot
    fi
    echo "### DONE ###"
else
    reboot
fi
SCRIPT

Vagrant.configure("2") do |config|
  wbid = 1
  offset = 0

  config.vm.provider "virtualbox" do |v|
    v.gui=false

  end



  ##### DEFINE VM for oob-mgmt-server #####
  config.vm.define "oob-mgmt-server" do |device|
    device.vm.hostname = "oob-mgmt-server"
    device.vm.box = "boxcutter/ubuntu1404"
    
    device.vm.provider "virtualbox" do |v|
      v.name = "#{wbid}_oob-mgmt-server"
      v.memory = 1024
    end
    device.vm.synced_folder ".", "/vagrant", disabled: true
      # UBUNTU DEVICES ONLY: Shorten Boot Process - remove \"Wait for Network
      device.vm.provision :shell , inline: "sudo sed -i 's/sleep [0-9]*/sleep 1/' /etc/init/failsafe.conf"

      # link for eth1 --> oob-mgmt-switch:swp1
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net54", auto_config: false , :mac => "44383900005F"
      

    device.vm.provider "virtualbox" do |vbox|
      vbox.customize ['modifyvm', :id, '--nicpromisc2', 'allow-vms']

      vbox.customize ["modifyvm", :id, "--nictype1", "virtio"]
    end

      # Fixes "stdin: is not a tty" message --> https://github.com/mitchellh/vagrant/issues/1673
      device.vm.provision :shell , inline: "(grep -q -E '^mesg n$' /root/.profile && sed -i 's/^mesg n$/tty -s \\&\\& mesg n/g' /root/.profile && echo 'Ignore the previous error \"stdin: is not a tty\" -- fixing this now...') || exit 0;"

      # Run Any Extra Config
      device.vm.provision :shell , path: "./helper_scripts/config_oob_server.sh"

      device.vm.provision "ansible" do |ansible|
          ansible.playbook = "./playbook/site.yml"
          ansible.extra_vars = {wbench_hosts: {
              
              
              
              
              
              
              
              
                  exit02: {ip: "192.168.100.42", mac: "A0:00:00:00:00:42"},
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
                  exit01: {ip: "192.168.100.41", mac: "A0:00:00:00:00:41"},
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
                  spine02: {ip: "192.168.100.22", mac: "A0:00:00:00:00:22"},
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
                  spine01: {ip: "192.168.100.21", mac: "A0:00:00:00:00:21"},
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
                  leaf04: {ip: "192.168.100.14", mac: "A0:00:00:00:00:14"},
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
                  leaf02: {ip: "192.168.100.12", mac: "A0:00:00:00:00:12"},
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
                  leaf03: {ip: "192.168.100.13", mac: "A0:00:00:00:00:13"},
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
                  leaf01: {ip: "192.168.100.11", mac: "A0:00:00:00:00:11"},
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
              
                  edge01: {ip: "192.168.100.51", mac: "A0:00:00:00:00:51"},
              
              
              
              
              
              
              
              
              
              
              
                  server01: {ip: "192.168.100.31", mac: "A0:00:00:00:00:31"},
              
              
              
              
              
              
              
              
              
              
              
                  server03: {ip: "192.168.100.33", mac: "A0:00:00:00:00:33"},
              
              
              
              
              
              
              
              
              
              
              
                  server02: {ip: "192.168.100.32", mac: "A0:00:00:00:00:32"},
              
              
              
              
              
              
              
              
              
              
              
                  server04: {ip: "192.168.100.34", mac: "A0:00:00:00:00:34"},
              
              
              
              
              
              
              
              
              
              
                              }}
        end

      # Apply the interface re-map
      device.vm.provision "file", source: "./helper_scripts/apply_udev.py", destination: "/home/vagrant/apply_udev.py"
      device.vm.provision :shell , inline: "chmod 755 /home/vagrant/apply_udev.py"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44383900005F eth1"


      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -vm -nv"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -s"
      device.vm.provision :shell , :inline => $script



  end

  ##### DEFINE VM for oob-mgmt-switch #####
  config.vm.define "oob-mgmt-switch" do |device|
    device.vm.hostname = "oob-mgmt-switch"
    device.vm.box = "CumulusCommunity/cumulus-vx"
    device.vm.box_version = "3.0.0"
    device.vm.provider "virtualbox" do |v|
      v.name = "#{wbid}_oob-mgmt-switch"
      v.memory = 256
    end
    device.vm.synced_folder ".", "/vagrant", disabled: true

      # link for swp1 --> oob-mgmt-server:eth1
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net54", auto_config: false , :mac => "443839000060"
      
      # link for swp2 --> server01:eth0
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net42", auto_config: false , :mac => "44383900004B"
      
      # link for swp3 --> server02:eth0
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net47", auto_config: false , :mac => "443839000054"
      
      # link for swp4 --> server03:eth0
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net3", auto_config: false , :mac => "443839000005"
      
      # link for swp5 --> server04:eth0
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net49", auto_config: false , :mac => "443839000056"
      
      # link for swp6 --> leaf01:eth0
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net20", auto_config: false , :mac => "443839000025"
      
      # link for swp7 --> leaf02:eth0
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net38", auto_config: false , :mac => "443839000045"
      
      # link for swp8 --> leaf03:eth0
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net28", auto_config: false , :mac => "443839000034"
      
      # link for swp9 --> leaf04:eth0
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net34", auto_config: false , :mac => "44383900003E"
      
      # link for swp10 --> spine01:eth0
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net31", auto_config: false , :mac => "443839000039"
      
      # link for swp11 --> spine02:eth0
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net59", auto_config: false , :mac => "443839000069"
      
      # link for swp12 --> exit01:eth0
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net9", auto_config: false , :mac => "443839000010"
      
      # link for swp13 --> exit02:eth0
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net48", auto_config: false , :mac => "443839000055"
      
      # link for swp14 --> edge01:eth0
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net40", auto_config: false , :mac => "443839000048"
      
      # link for swp15 --> internet:eth0
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net35", auto_config: false , :mac => "443839000040"
      

    device.vm.provider "virtualbox" do |vbox|
      vbox.customize ['modifyvm', :id, '--nicpromisc2', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc3', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc4', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc5', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc6', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc7', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc8', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc9', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc10', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc11', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc12', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc13', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc14', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc15', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc16', 'allow-vms']

      vbox.customize ["modifyvm", :id, "--nictype1", "virtio"]
    end

      # Fixes "stdin: is not a tty" message --> https://github.com/mitchellh/vagrant/issues/1673
      device.vm.provision :shell , inline: "(grep -q -E '^mesg n$' /root/.profile && sed -i 's/^mesg n$/tty -s \\&\\& mesg n/g' /root/.profile && echo 'Ignore the previous error \"stdin: is not a tty\" -- fixing this now...') || exit 0;"

      # Run Any Extra Config
      device.vm.provision :shell , path: "./helper_scripts/config_oob_switch.sh"



      # Apply the interface re-map
      device.vm.provision "file", source: "./helper_scripts/apply_udev.py", destination: "/home/vagrant/apply_udev.py"
      device.vm.provision :shell , inline: "chmod 755 /home/vagrant/apply_udev.py"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000060 swp1"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44383900004B swp2"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000054 swp3"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000005 swp4"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000056 swp5"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000025 swp6"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000045 swp7"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000034 swp8"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44383900003E swp9"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000039 swp10"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000069 swp11"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000010 swp12"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000055 swp13"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000048 swp14"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000040 swp15"


      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -vm -nv"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -s"
      device.vm.provision :shell , :inline => $script



  end

  ##### DEFINE VM for exit02 #####
  config.vm.define "exit02" do |device|
    device.vm.hostname = "exit02"
    device.vm.box = "CumulusCommunity/cumulus-vx"
    device.vm.box_version = "3.0.0"
    device.vm.provider "virtualbox" do |v|
      v.name = "#{wbid}_exit02"
      v.memory = 512
    end
    device.vm.synced_folder ".", "/vagrant", disabled: true

      # link for eth0 --> oob-mgmt-switch:swp13
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net48", auto_config: false , :mac => "A00000000042"
      
      # link for swp1 --> edge01:eth2
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net7", auto_config: false , :mac => "44383900000D"
      
      # link for swp44 --> internet:swp2
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net39", auto_config: false , :mac => "443839000047"
      
      # link for swp45 --> exit02:swp46
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net30", auto_config: false , :mac => "443839000037"
      
      # link for swp46 --> exit02:swp45
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net30", auto_config: false , :mac => "443839000038"
      
      # link for swp47 --> exit02:swp48
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net33", auto_config: false , :mac => "44383900003C"
      
      # link for swp48 --> exit02:swp47
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net33", auto_config: false , :mac => "44383900003D"
      
      # link for swp49 --> exit01:swp49
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net24", auto_config: false , :mac => "44383900002D"
      
      # link for swp50 --> exit01:swp50
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net14", auto_config: false , :mac => "44383900001A"
      
      # link for swp51 --> spine01:swp29
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net21", auto_config: false , :mac => "443839000026"
      
      # link for swp52 --> spine02:swp29
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net53", auto_config: false , :mac => "44383900005D"
      

    device.vm.provider "virtualbox" do |vbox|
      vbox.customize ['modifyvm', :id, '--nicpromisc2', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc3', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc4', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc5', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc6', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc7', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc8', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc9', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc10', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc11', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc12', 'allow-vms']

      vbox.customize ["modifyvm", :id, "--nictype1", "virtio"]
    end

      # Fixes "stdin: is not a tty" message --> https://github.com/mitchellh/vagrant/issues/1673
      device.vm.provision :shell , inline: "(grep -q -E '^mesg n$' /root/.profile && sed -i 's/^mesg n$/tty -s \\&\\& mesg n/g' /root/.profile && echo 'Ignore the previous error \"stdin: is not a tty\" -- fixing this now...') || exit 0;"

      # Run Any Extra Config
      device.vm.provision :shell , path: "./helper_scripts/config_switch.sh"



      # Apply the interface re-map
      device.vm.provision "file", source: "./helper_scripts/apply_udev.py", destination: "/home/vagrant/apply_udev.py"
      device.vm.provision :shell , inline: "chmod 755 /home/vagrant/apply_udev.py"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a A0:00:00:00:00:42 eth0"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44383900000D swp1"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000047 swp44"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000037 swp45"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000038 swp46"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44383900003C swp47"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44383900003D swp48"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44383900002D swp49"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44383900001A swp50"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000026 swp51"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44383900005D swp52"


      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -vm "
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -s"
      device.vm.provision :shell , :inline => $script



  end

  ##### DEFINE VM for exit01 #####
  config.vm.define "exit01" do |device|
    device.vm.hostname = "exit01"
    device.vm.box = "CumulusCommunity/cumulus-vx"
    device.vm.box_version = "3.0.0"
    device.vm.provider "virtualbox" do |v|
      v.name = "#{wbid}_exit01"
      v.memory = 512
    end
    device.vm.synced_folder ".", "/vagrant", disabled: true

      # link for eth0 --> oob-mgmt-switch:swp12
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net9", auto_config: false , :mac => "A00000000041"
      
      # link for swp1 --> edge01:eth1
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net46", auto_config: false , :mac => "443839000053"
      
      # link for swp44 --> internet:swp1
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net5", auto_config: false , :mac => "443839000009"
      
      # link for swp45 --> exit01:swp46
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net43", auto_config: false , :mac => "44383900004C"
      
      # link for swp46 --> exit01:swp45
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net43", auto_config: false , :mac => "44383900004D"
      
      # link for swp47 --> exit01:swp48
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net11", auto_config: false , :mac => "443839000013"
      
      # link for swp48 --> exit01:swp47
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net11", auto_config: false , :mac => "443839000014"
      
      # link for swp49 --> exit02:swp49
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net24", auto_config: false , :mac => "44383900002C"
      
      # link for swp50 --> exit02:swp50
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net14", auto_config: false , :mac => "443839000019"
      
      # link for swp51 --> spine01:swp30
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net6", auto_config: false , :mac => "44383900000A"
      
      # link for swp52 --> spine02:swp30
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net56", auto_config: false , :mac => "443839000063"
      

    device.vm.provider "virtualbox" do |vbox|
      vbox.customize ['modifyvm', :id, '--nicpromisc2', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc3', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc4', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc5', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc6', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc7', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc8', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc9', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc10', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc11', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc12', 'allow-vms']

      vbox.customize ["modifyvm", :id, "--nictype1", "virtio"]
    end

      # Fixes "stdin: is not a tty" message --> https://github.com/mitchellh/vagrant/issues/1673
      device.vm.provision :shell , inline: "(grep -q -E '^mesg n$' /root/.profile && sed -i 's/^mesg n$/tty -s \\&\\& mesg n/g' /root/.profile && echo 'Ignore the previous error \"stdin: is not a tty\" -- fixing this now...') || exit 0;"

      # Run Any Extra Config
      device.vm.provision :shell , path: "./helper_scripts/config_switch.sh"



      # Apply the interface re-map
      device.vm.provision "file", source: "./helper_scripts/apply_udev.py", destination: "/home/vagrant/apply_udev.py"
      device.vm.provision :shell , inline: "chmod 755 /home/vagrant/apply_udev.py"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a A0:00:00:00:00:41 eth0"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000053 swp1"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000009 swp44"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44383900004C swp45"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44383900004D swp46"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000013 swp47"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000014 swp48"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44383900002C swp49"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000019 swp50"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44383900000A swp51"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000063 swp52"


      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -vm "
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -s"
      device.vm.provision :shell , :inline => $script



  end

  ##### DEFINE VM for spine02 #####
  config.vm.define "spine02" do |device|
    device.vm.hostname = "spine02"
    device.vm.box = "CumulusCommunity/cumulus-vx"
    device.vm.box_version = "3.0.0"
    device.vm.provider "virtualbox" do |v|
      v.name = "#{wbid}_spine02"
      v.memory = 512
    end
    device.vm.synced_folder ".", "/vagrant", disabled: true

      # link for eth0 --> oob-mgmt-switch:swp11
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net59", auto_config: false , :mac => "A00000000022"
      
      # link for swp1 --> leaf01:swp52
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net23", auto_config: false , :mac => "44383900002B"
      
      # link for swp2 --> leaf02:swp52
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net58", auto_config: false , :mac => "443839000068"
      
      # link for swp3 --> leaf03:swp52
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net17", auto_config: false , :mac => "443839000020"
      
      # link for swp4 --> leaf04:swp52
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net44", auto_config: false , :mac => "44383900004F"
      
      # link for swp29 --> exit02:swp52
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net53", auto_config: false , :mac => "44383900005E"
      
      # link for swp30 --> exit01:swp52
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net56", auto_config: false , :mac => "443839000064"
      
      # link for swp31 --> spine01:swp31
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net45", auto_config: false , :mac => "443839000051"
      
      # link for swp32 --> spine01:swp32
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net36", auto_config: false , :mac => "443839000042"
      

    device.vm.provider "virtualbox" do |vbox|
      vbox.customize ['modifyvm', :id, '--nicpromisc2', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc3', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc4', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc5', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc6', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc7', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc8', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc9', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc10', 'allow-vms']

      vbox.customize ["modifyvm", :id, "--nictype1", "virtio"]
    end

      # Fixes "stdin: is not a tty" message --> https://github.com/mitchellh/vagrant/issues/1673
      device.vm.provision :shell , inline: "(grep -q -E '^mesg n$' /root/.profile && sed -i 's/^mesg n$/tty -s \\&\\& mesg n/g' /root/.profile && echo 'Ignore the previous error \"stdin: is not a tty\" -- fixing this now...') || exit 0;"

      # Run Any Extra Config
      device.vm.provision :shell , path: "./helper_scripts/config_switch.sh"



      # Apply the interface re-map
      device.vm.provision "file", source: "./helper_scripts/apply_udev.py", destination: "/home/vagrant/apply_udev.py"
      device.vm.provision :shell , inline: "chmod 755 /home/vagrant/apply_udev.py"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a A0:00:00:00:00:22 eth0"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44383900002B swp1"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000068 swp2"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000020 swp3"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44383900004F swp4"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44383900005E swp29"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000064 swp30"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000051 swp31"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000042 swp32"


      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -vm "
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -s"
      device.vm.provision :shell , :inline => $script



  end

  ##### DEFINE VM for spine01 #####
  config.vm.define "spine01" do |device|
    device.vm.hostname = "spine01"
    device.vm.box = "CumulusCommunity/cumulus-vx"
    device.vm.box_version = "3.0.0"
    device.vm.provider "virtualbox" do |v|
      v.name = "#{wbid}_spine01"
      v.memory = 512
    end
    device.vm.synced_folder ".", "/vagrant", disabled: true

      # link for eth0 --> oob-mgmt-switch:swp10
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net31", auto_config: false , :mac => "A00000000021"
      
      # link for swp1 --> leaf01:swp51
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net52", auto_config: false , :mac => "44383900005C"
      
      # link for swp2 --> leaf02:swp51
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net25", auto_config: false , :mac => "44383900002F"
      
      # link for swp3 --> leaf03:swp51
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net50", auto_config: false , :mac => "443839000058"
      
      # link for swp4 --> leaf04:swp51
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net37", auto_config: false , :mac => "443839000044"
      
      # link for swp29 --> exit02:swp51
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net21", auto_config: false , :mac => "443839000027"
      
      # link for swp30 --> exit01:swp51
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net6", auto_config: false , :mac => "44383900000B"
      
      # link for swp31 --> spine02:swp31
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net45", auto_config: false , :mac => "443839000050"
      
      # link for swp32 --> spine02:swp32
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net36", auto_config: false , :mac => "443839000041"
      

    device.vm.provider "virtualbox" do |vbox|
      vbox.customize ['modifyvm', :id, '--nicpromisc2', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc3', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc4', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc5', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc6', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc7', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc8', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc9', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc10', 'allow-vms']

      vbox.customize ["modifyvm", :id, "--nictype1", "virtio"]
    end

      # Fixes "stdin: is not a tty" message --> https://github.com/mitchellh/vagrant/issues/1673
      device.vm.provision :shell , inline: "(grep -q -E '^mesg n$' /root/.profile && sed -i 's/^mesg n$/tty -s \\&\\& mesg n/g' /root/.profile && echo 'Ignore the previous error \"stdin: is not a tty\" -- fixing this now...') || exit 0;"

      # Run Any Extra Config
      device.vm.provision :shell , path: "./helper_scripts/config_switch.sh"



      # Apply the interface re-map
      device.vm.provision "file", source: "./helper_scripts/apply_udev.py", destination: "/home/vagrant/apply_udev.py"
      device.vm.provision :shell , inline: "chmod 755 /home/vagrant/apply_udev.py"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a A0:00:00:00:00:21 eth0"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44383900005C swp1"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44383900002F swp2"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000058 swp3"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000044 swp4"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000027 swp29"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44383900000B swp30"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000050 swp31"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000041 swp32"


      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -vm "
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -s"
      device.vm.provision :shell , :inline => $script



  end

  ##### DEFINE VM for leaf04 #####
  config.vm.define "leaf04" do |device|
    device.vm.hostname = "leaf04"
    device.vm.box = "CumulusCommunity/cumulus-vx"
    device.vm.box_version = "3.0.0"
    device.vm.provider "virtualbox" do |v|
      v.name = "#{wbid}_leaf04"
      v.memory = 512
    end
    device.vm.synced_folder ".", "/vagrant", disabled: true

      # link for eth0 --> oob-mgmt-switch:swp9
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net34", auto_config: false , :mac => "A00000000014"
      
      # link for swp1 --> server03:eth2
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net57", auto_config: false , :mac => "443839000066"
      
      # link for swp2 --> server04:eth2
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net27", auto_config: false , :mac => "443839000033"
      
      # link for swp45 --> leaf04:swp46
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net16", auto_config: false , :mac => "44383900001D"
      
      # link for swp46 --> leaf04:swp45
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net16", auto_config: false , :mac => "44383900001E"
      
      # link for swp47 --> leaf04:swp48
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net32", auto_config: false , :mac => "44383900003A"
      
      # link for swp48 --> leaf04:swp47
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net32", auto_config: false , :mac => "44383900003B"
      
      # link for swp49 --> leaf03:swp49
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net29", auto_config: false , :mac => "443839000036"
      
      # link for swp50 --> leaf03:swp50
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net4", auto_config: false , :mac => "443839000007"
      
      # link for swp51 --> spine01:swp4
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net37", auto_config: false , :mac => "443839000043"
      
      # link for swp52 --> spine02:swp4
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net44", auto_config: false , :mac => "44383900004E"
      

    device.vm.provider "virtualbox" do |vbox|
      vbox.customize ['modifyvm', :id, '--nicpromisc2', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc3', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc4', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc5', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc6', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc7', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc8', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc9', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc10', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc11', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc12', 'allow-vms']

      vbox.customize ["modifyvm", :id, "--nictype1", "virtio"]
    end

      # Fixes "stdin: is not a tty" message --> https://github.com/mitchellh/vagrant/issues/1673
      device.vm.provision :shell , inline: "(grep -q -E '^mesg n$' /root/.profile && sed -i 's/^mesg n$/tty -s \\&\\& mesg n/g' /root/.profile && echo 'Ignore the previous error \"stdin: is not a tty\" -- fixing this now...') || exit 0;"

      # Run Any Extra Config
      device.vm.provision :shell , path: "./helper_scripts/config_switch.sh"



      # Apply the interface re-map
      device.vm.provision "file", source: "./helper_scripts/apply_udev.py", destination: "/home/vagrant/apply_udev.py"
      device.vm.provision :shell , inline: "chmod 755 /home/vagrant/apply_udev.py"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a A0:00:00:00:00:14 eth0"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000066 swp1"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000033 swp2"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44383900001D swp45"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44383900001E swp46"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44383900003A swp47"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44383900003B swp48"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000036 swp49"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000007 swp50"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000043 swp51"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44383900004E swp52"


      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -vm "
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -s"
      device.vm.provision :shell , :inline => $script



  end

  ##### DEFINE VM for leaf02 #####
  config.vm.define "leaf02" do |device|
    device.vm.hostname = "leaf02"
    device.vm.box = "CumulusCommunity/cumulus-vx"
    device.vm.box_version = "3.0.0"
    device.vm.provider "virtualbox" do |v|
      v.name = "#{wbid}_leaf02"
      v.memory = 512
    end
    device.vm.synced_folder ".", "/vagrant", disabled: true

      # link for eth0 --> oob-mgmt-switch:swp7
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net38", auto_config: false , :mac => "A00000000012"
      
      # link for swp1 --> server01:eth2
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net13", auto_config: false , :mac => "443839000018"
      
      # link for swp2 --> server02:eth2
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net15", auto_config: false , :mac => "44383900001C"
      
      # link for swp45 --> leaf02:swp46
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net8", auto_config: false , :mac => "44383900000E"
      
      # link for swp46 --> leaf02:swp45
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net8", auto_config: false , :mac => "44383900000F"
      
      # link for swp47 --> leaf02:swp48
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net55", auto_config: false , :mac => "443839000061"
      
      # link for swp48 --> leaf02:swp47
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net55", auto_config: false , :mac => "443839000062"
      
      # link for swp49 --> leaf01:swp49
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net10", auto_config: false , :mac => "443839000012"
      
      # link for swp50 --> leaf01:swp50
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net1", auto_config: false , :mac => "443839000002"
      
      # link for swp51 --> spine01:swp2
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net25", auto_config: false , :mac => "44383900002E"
      
      # link for swp52 --> spine02:swp2
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net58", auto_config: false , :mac => "443839000067"
      

    device.vm.provider "virtualbox" do |vbox|
      vbox.customize ['modifyvm', :id, '--nicpromisc2', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc3', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc4', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc5', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc6', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc7', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc8', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc9', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc10', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc11', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc12', 'allow-vms']

      vbox.customize ["modifyvm", :id, "--nictype1", "virtio"]
    end

      # Fixes "stdin: is not a tty" message --> https://github.com/mitchellh/vagrant/issues/1673
      device.vm.provision :shell , inline: "(grep -q -E '^mesg n$' /root/.profile && sed -i 's/^mesg n$/tty -s \\&\\& mesg n/g' /root/.profile && echo 'Ignore the previous error \"stdin: is not a tty\" -- fixing this now...') || exit 0;"

      # Run Any Extra Config
      device.vm.provision :shell , path: "./helper_scripts/config_switch.sh"



      # Apply the interface re-map
      device.vm.provision "file", source: "./helper_scripts/apply_udev.py", destination: "/home/vagrant/apply_udev.py"
      device.vm.provision :shell , inline: "chmod 755 /home/vagrant/apply_udev.py"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a A0:00:00:00:00:12 eth0"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000018 swp1"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44383900001C swp2"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44383900000E swp45"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44383900000F swp46"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000061 swp47"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000062 swp48"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000012 swp49"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000002 swp50"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44383900002E swp51"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000067 swp52"


      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -vm "
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -s"
      device.vm.provision :shell , :inline => $script



  end

  ##### DEFINE VM for leaf03 #####
  config.vm.define "leaf03" do |device|
    device.vm.hostname = "leaf03"
    device.vm.box = "CumulusCommunity/cumulus-vx"
    device.vm.box_version = "3.0.0"
    device.vm.provider "virtualbox" do |v|
      v.name = "#{wbid}_leaf03"
      v.memory = 512
    end
    device.vm.synced_folder ".", "/vagrant", disabled: true

      # link for eth0 --> oob-mgmt-switch:swp8
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net28", auto_config: false , :mac => "A00000000013"
      
      # link for swp1 --> server03:eth1
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net22", auto_config: false , :mac => "443839000029"
      
      # link for swp2 --> server04:eth1
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net19", auto_config: false , :mac => "443839000024"
      
      # link for swp45 --> leaf03:swp46
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net26", auto_config: false , :mac => "443839000030"
      
      # link for swp46 --> leaf03:swp45
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net26", auto_config: false , :mac => "443839000031"
      
      # link for swp47 --> leaf03:swp48
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net51", auto_config: false , :mac => "443839000059"
      
      # link for swp48 --> leaf03:swp47
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net51", auto_config: false , :mac => "44383900005A"
      
      # link for swp49 --> leaf04:swp49
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net29", auto_config: false , :mac => "443839000035"
      
      # link for swp50 --> leaf04:swp50
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net4", auto_config: false , :mac => "443839000006"
      
      # link for swp51 --> spine01:swp3
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net50", auto_config: false , :mac => "443839000057"
      
      # link for swp52 --> spine02:swp3
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net17", auto_config: false , :mac => "44383900001F"
      

    device.vm.provider "virtualbox" do |vbox|
      vbox.customize ['modifyvm', :id, '--nicpromisc2', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc3', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc4', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc5', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc6', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc7', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc8', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc9', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc10', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc11', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc12', 'allow-vms']

      vbox.customize ["modifyvm", :id, "--nictype1", "virtio"]
    end

      # Fixes "stdin: is not a tty" message --> https://github.com/mitchellh/vagrant/issues/1673
      device.vm.provision :shell , inline: "(grep -q -E '^mesg n$' /root/.profile && sed -i 's/^mesg n$/tty -s \\&\\& mesg n/g' /root/.profile && echo 'Ignore the previous error \"stdin: is not a tty\" -- fixing this now...') || exit 0;"

      # Run Any Extra Config
      device.vm.provision :shell , path: "./helper_scripts/config_switch.sh"



      # Apply the interface re-map
      device.vm.provision "file", source: "./helper_scripts/apply_udev.py", destination: "/home/vagrant/apply_udev.py"
      device.vm.provision :shell , inline: "chmod 755 /home/vagrant/apply_udev.py"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a A0:00:00:00:00:13 eth0"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000029 swp1"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000024 swp2"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000030 swp45"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000031 swp46"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000059 swp47"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44383900005A swp48"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000035 swp49"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000006 swp50"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000057 swp51"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44383900001F swp52"


      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -vm "
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -s"
      device.vm.provision :shell , :inline => $script



  end

  ##### DEFINE VM for leaf01 #####
  config.vm.define "leaf01" do |device|
    device.vm.hostname = "leaf01"
    device.vm.box = "CumulusCommunity/cumulus-vx"
    device.vm.box_version = "3.0.0"
    device.vm.provider "virtualbox" do |v|
      v.name = "#{wbid}_leaf01"
      v.memory = 512
    end
    device.vm.synced_folder ".", "/vagrant", disabled: true

      # link for eth0 --> oob-mgmt-switch:swp6
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net20", auto_config: false , :mac => "A00000000011"
      
      # link for swp1 --> server01:eth1
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net2", auto_config: false , :mac => "443839000004"
      
      # link for swp2 --> server02:eth1
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net12", auto_config: false , :mac => "443839000016"
      
      # link for swp45 --> leaf01:swp46
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net18", auto_config: false , :mac => "443839000021"
      
      # link for swp46 --> leaf01:swp45
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net18", auto_config: false , :mac => "443839000022"
      
      # link for swp47 --> leaf01:swp48
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net41", auto_config: false , :mac => "443839000049"
      
      # link for swp48 --> leaf01:swp47
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net41", auto_config: false , :mac => "44383900004A"
      
      # link for swp49 --> leaf02:swp49
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net10", auto_config: false , :mac => "443839000011"
      
      # link for swp50 --> leaf02:swp50
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net1", auto_config: false , :mac => "443839000001"
      
      # link for swp51 --> spine01:swp1
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net52", auto_config: false , :mac => "44383900005B"
      
      # link for swp52 --> spine02:swp1
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net23", auto_config: false , :mac => "44383900002A"
      

    device.vm.provider "virtualbox" do |vbox|
      vbox.customize ['modifyvm', :id, '--nicpromisc2', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc3', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc4', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc5', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc6', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc7', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc8', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc9', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc10', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc11', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc12', 'allow-vms']

      vbox.customize ["modifyvm", :id, "--nictype1", "virtio"]
    end

      # Fixes "stdin: is not a tty" message --> https://github.com/mitchellh/vagrant/issues/1673
      device.vm.provision :shell , inline: "(grep -q -E '^mesg n$' /root/.profile && sed -i 's/^mesg n$/tty -s \\&\\& mesg n/g' /root/.profile && echo 'Ignore the previous error \"stdin: is not a tty\" -- fixing this now...') || exit 0;"

      # Run Any Extra Config
      device.vm.provision :shell , path: "./helper_scripts/config_switch.sh"



      # Apply the interface re-map
      device.vm.provision "file", source: "./helper_scripts/apply_udev.py", destination: "/home/vagrant/apply_udev.py"
      device.vm.provision :shell , inline: "chmod 755 /home/vagrant/apply_udev.py"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a A0:00:00:00:00:11 eth0"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000004 swp1"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000016 swp2"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000021 swp45"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000022 swp46"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000049 swp47"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44383900004A swp48"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000011 swp49"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000001 swp50"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44383900005B swp51"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44383900002A swp52"


      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -vm "
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -s"
      device.vm.provision :shell , :inline => $script



  end

  ##### DEFINE VM for edge01 #####
  config.vm.define "edge01" do |device|
    device.vm.hostname = "edge01"
    device.vm.box = "boxcutter/ubuntu1404"
    
    device.vm.provider "virtualbox" do |v|
      v.name = "#{wbid}_edge01"
      v.memory = 512
    end
    device.vm.synced_folder ".", "/vagrant", disabled: true
      # UBUNTU DEVICES ONLY: Shorten Boot Process - remove \"Wait for Network
      device.vm.provision :shell , inline: "sudo sed -i 's/sleep [0-9]*/sleep 1/' /etc/init/failsafe.conf"

      # link for eth0 --> oob-mgmt-switch:swp14
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net40", auto_config: false , :mac => "A00000000051"
      
      # link for eth1 --> exit01:swp1
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net46", auto_config: false , :mac => "443839000052"
      
      # link for eth2 --> exit02:swp1
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net7", auto_config: false , :mac => "44383900000C"
      

    device.vm.provider "virtualbox" do |vbox|
      vbox.customize ['modifyvm', :id, '--nicpromisc2', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc3', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc4', 'allow-vms']

      vbox.customize ["modifyvm", :id, "--nictype1", "virtio"]
    end

      # Fixes "stdin: is not a tty" message --> https://github.com/mitchellh/vagrant/issues/1673
      device.vm.provision :shell , inline: "(grep -q -E '^mesg n$' /root/.profile && sed -i 's/^mesg n$/tty -s \\&\\& mesg n/g' /root/.profile && echo 'Ignore the previous error \"stdin: is not a tty\" -- fixing this now...') || exit 0;"

      # Run Any Extra Config
      device.vm.provision :shell , path: "./helper_scripts/config_server.sh"



      # Apply the interface re-map
      device.vm.provision "file", source: "./helper_scripts/apply_udev.py", destination: "/home/vagrant/apply_udev.py"
      device.vm.provision :shell , inline: "chmod 755 /home/vagrant/apply_udev.py"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a A0:00:00:00:00:51 eth0"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000052 eth1"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44383900000C eth2"


      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -vm "
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -s"
      device.vm.provision :shell , :inline => $script



  end

  ##### DEFINE VM for server01 #####
  config.vm.define "server01" do |device|
    device.vm.hostname = "server01"
    device.vm.box = "boxcutter/ubuntu1404"
    
    device.vm.provider "virtualbox" do |v|
      v.name = "#{wbid}_server01"
      v.memory = 512
    end
    device.vm.synced_folder ".", "/vagrant", disabled: true
      # UBUNTU DEVICES ONLY: Shorten Boot Process - remove \"Wait for Network
      device.vm.provision :shell , inline: "sudo sed -i 's/sleep [0-9]*/sleep 1/' /etc/init/failsafe.conf"

      # link for eth0 --> oob-mgmt-switch:swp2
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net42", auto_config: false , :mac => "A00000000031"
      
      # link for eth1 --> leaf01:swp1
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net2", auto_config: false , :mac => "443839000003"
      
      # link for eth2 --> leaf02:swp1
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net13", auto_config: false , :mac => "443839000017"
      

    device.vm.provider "virtualbox" do |vbox|
      vbox.customize ['modifyvm', :id, '--nicpromisc2', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc3', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc4', 'allow-vms']

      vbox.customize ["modifyvm", :id, "--nictype1", "virtio"]
    end

      # Fixes "stdin: is not a tty" message --> https://github.com/mitchellh/vagrant/issues/1673
      device.vm.provision :shell , inline: "(grep -q -E '^mesg n$' /root/.profile && sed -i 's/^mesg n$/tty -s \\&\\& mesg n/g' /root/.profile && echo 'Ignore the previous error \"stdin: is not a tty\" -- fixing this now...') || exit 0;"

      # Run Any Extra Config
      device.vm.provision :shell , path: "./helper_scripts/config_server.sh"



      # Apply the interface re-map
      device.vm.provision "file", source: "./helper_scripts/apply_udev.py", destination: "/home/vagrant/apply_udev.py"
      device.vm.provision :shell , inline: "chmod 755 /home/vagrant/apply_udev.py"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a A0:00:00:00:00:31 eth0"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000003 eth1"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000017 eth2"


      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -vm "
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -s"
      device.vm.provision :shell , :inline => $script



  end

  ##### DEFINE VM for server03 #####
  config.vm.define "server03" do |device|
    device.vm.hostname = "server03"
    device.vm.box = "boxcutter/ubuntu1404"
    
    device.vm.provider "virtualbox" do |v|
      v.name = "#{wbid}_server03"
      v.memory = 512
    end
    device.vm.synced_folder ".", "/vagrant", disabled: true
      # UBUNTU DEVICES ONLY: Shorten Boot Process - remove \"Wait for Network
      device.vm.provision :shell , inline: "sudo sed -i 's/sleep [0-9]*/sleep 1/' /etc/init/failsafe.conf"

      # link for eth0 --> oob-mgmt-switch:swp4
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net3", auto_config: false , :mac => "A00000000033"
      
      # link for eth1 --> leaf03:swp1
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net22", auto_config: false , :mac => "443839000028"
      
      # link for eth2 --> leaf04:swp1
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net57", auto_config: false , :mac => "443839000065"
      

    device.vm.provider "virtualbox" do |vbox|
      vbox.customize ['modifyvm', :id, '--nicpromisc2', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc3', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc4', 'allow-vms']

      vbox.customize ["modifyvm", :id, "--nictype1", "virtio"]
    end

      # Fixes "stdin: is not a tty" message --> https://github.com/mitchellh/vagrant/issues/1673
      device.vm.provision :shell , inline: "(grep -q -E '^mesg n$' /root/.profile && sed -i 's/^mesg n$/tty -s \\&\\& mesg n/g' /root/.profile && echo 'Ignore the previous error \"stdin: is not a tty\" -- fixing this now...') || exit 0;"

      # Run Any Extra Config
      device.vm.provision :shell , path: "./helper_scripts/config_server.sh"



      # Apply the interface re-map
      device.vm.provision "file", source: "./helper_scripts/apply_udev.py", destination: "/home/vagrant/apply_udev.py"
      device.vm.provision :shell , inline: "chmod 755 /home/vagrant/apply_udev.py"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a A0:00:00:00:00:33 eth0"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000028 eth1"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000065 eth2"


      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -vm "
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -s"
      device.vm.provision :shell , :inline => $script



  end

  ##### DEFINE VM for server02 #####
  config.vm.define "server02" do |device|
    device.vm.hostname = "server02"
    device.vm.box = "boxcutter/ubuntu1404"
    
    device.vm.provider "virtualbox" do |v|
      v.name = "#{wbid}_server02"
      v.memory = 512
    end
    device.vm.synced_folder ".", "/vagrant", disabled: true
      # UBUNTU DEVICES ONLY: Shorten Boot Process - remove \"Wait for Network
      device.vm.provision :shell , inline: "sudo sed -i 's/sleep [0-9]*/sleep 1/' /etc/init/failsafe.conf"

      # link for eth0 --> oob-mgmt-switch:swp3
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net47", auto_config: false , :mac => "A00000000032"
      
      # link for eth1 --> leaf01:swp2
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net12", auto_config: false , :mac => "443839000015"
      
      # link for eth2 --> leaf02:swp2
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net15", auto_config: false , :mac => "44383900001B"
      

    device.vm.provider "virtualbox" do |vbox|
      vbox.customize ['modifyvm', :id, '--nicpromisc2', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc3', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc4', 'allow-vms']

      vbox.customize ["modifyvm", :id, "--nictype1", "virtio"]
    end

      # Fixes "stdin: is not a tty" message --> https://github.com/mitchellh/vagrant/issues/1673
      device.vm.provision :shell , inline: "(grep -q -E '^mesg n$' /root/.profile && sed -i 's/^mesg n$/tty -s \\&\\& mesg n/g' /root/.profile && echo 'Ignore the previous error \"stdin: is not a tty\" -- fixing this now...') || exit 0;"

      # Run Any Extra Config
      device.vm.provision :shell , path: "./helper_scripts/config_server.sh"



      # Apply the interface re-map
      device.vm.provision "file", source: "./helper_scripts/apply_udev.py", destination: "/home/vagrant/apply_udev.py"
      device.vm.provision :shell , inline: "chmod 755 /home/vagrant/apply_udev.py"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a A0:00:00:00:00:32 eth0"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000015 eth1"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44383900001B eth2"


      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -vm "
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -s"
      device.vm.provision :shell , :inline => $script



  end

  ##### DEFINE VM for server04 #####
  config.vm.define "server04" do |device|
    device.vm.hostname = "server04"
    device.vm.box = "boxcutter/ubuntu1404"
    
    device.vm.provider "virtualbox" do |v|
      v.name = "#{wbid}_server04"
      v.memory = 512
    end
    device.vm.synced_folder ".", "/vagrant", disabled: true
      # UBUNTU DEVICES ONLY: Shorten Boot Process - remove \"Wait for Network
      device.vm.provision :shell , inline: "sudo sed -i 's/sleep [0-9]*/sleep 1/' /etc/init/failsafe.conf"

      # link for eth0 --> oob-mgmt-switch:swp5
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net49", auto_config: false , :mac => "A00000000034"
      
      # link for eth1 --> leaf03:swp2
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net19", auto_config: false , :mac => "443839000023"
      
      # link for eth2 --> leaf04:swp2
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net27", auto_config: false , :mac => "443839000032"
      

    device.vm.provider "virtualbox" do |vbox|
      vbox.customize ['modifyvm', :id, '--nicpromisc2', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc3', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc4', 'allow-vms']

      vbox.customize ["modifyvm", :id, "--nictype1", "virtio"]
    end

      # Fixes "stdin: is not a tty" message --> https://github.com/mitchellh/vagrant/issues/1673
      device.vm.provision :shell , inline: "(grep -q -E '^mesg n$' /root/.profile && sed -i 's/^mesg n$/tty -s \\&\\& mesg n/g' /root/.profile && echo 'Ignore the previous error \"stdin: is not a tty\" -- fixing this now...') || exit 0;"

      # Run Any Extra Config
      device.vm.provision :shell , path: "./helper_scripts/config_server.sh"



      # Apply the interface re-map
      device.vm.provision "file", source: "./helper_scripts/apply_udev.py", destination: "/home/vagrant/apply_udev.py"
      device.vm.provision :shell , inline: "chmod 755 /home/vagrant/apply_udev.py"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a A0:00:00:00:00:34 eth0"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000023 eth1"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000032 eth2"


      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -vm "
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -s"
      device.vm.provision :shell , :inline => $script



  end

  ##### DEFINE VM for internet #####
  config.vm.define "internet" do |device|
    device.vm.hostname = "internet"
    device.vm.box = "CumulusCommunity/cumulus-vx"
    device.vm.box_version = "3.0.0"
    device.vm.provider "virtualbox" do |v|
      v.name = "#{wbid}_internet"
      v.memory = 256
    end
    device.vm.synced_folder ".", "/vagrant", disabled: true

      # link for eth0 --> oob-mgmt-switch:swp15
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net35", auto_config: false , :mac => "44383900003F"
      
      # link for swp1 --> exit01:swp44
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net5", auto_config: false , :mac => "443839000008"
      
      # link for swp2 --> exit02:swp44
      device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net39", auto_config: false , :mac => "443839000046"
      

    device.vm.provider "virtualbox" do |vbox|
      vbox.customize ['modifyvm', :id, '--nicpromisc2', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc3', 'allow-vms']
      vbox.customize ['modifyvm', :id, '--nicpromisc4', 'allow-vms']

      vbox.customize ["modifyvm", :id, "--nictype1", "virtio"]
    end

      # Fixes "stdin: is not a tty" message --> https://github.com/mitchellh/vagrant/issues/1673
      device.vm.provision :shell , inline: "(grep -q -E '^mesg n$' /root/.profile && sed -i 's/^mesg n$/tty -s \\&\\& mesg n/g' /root/.profile && echo 'Ignore the previous error \"stdin: is not a tty\" -- fixing this now...') || exit 0;"

      # Run Any Extra Config
      device.vm.provision :shell , path: "./helper_scripts/config_internet.sh"



      # Apply the interface re-map
      device.vm.provision "file", source: "./helper_scripts/apply_udev.py", destination: "/home/vagrant/apply_udev.py"
      device.vm.provision :shell , inline: "chmod 755 /home/vagrant/apply_udev.py"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44383900003F eth0"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000008 swp1"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 443839000046 swp2"


      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -vm --vagrant-name=swp48"
      device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -s"
      device.vm.provision :shell , :inline => $script



  end



end