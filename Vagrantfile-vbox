# Created by Topology-Converter v4.5.0
#    https://github.com/cumulusnetworks/topology_converter
#    using topology data from: topology.dot
#
#    NOTE: in order to use this Vagrantfile you will need:
#       -Vagrant(v1.8.1+) installed: http://www.vagrantup.com/downloads
#       -Cumulus Plugin for Vagrant installed: $ vagrant plugin install vagrant-cumulus
#       -the "helper_scripts" directory that comes packaged with topology-converter.py
#       -Virtualbox installed: https://www.virtualbox.org/wiki/Downloads



# Check required plugins

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
        echo "### Disabling ZTP service..."
        systemctl stop ztp.service
        ztp -d 2>&1
        echo "### Resetting ZTP to work next boot..."
        ztp -R 2>&1
        echo "### Rebooting Switch to Apply Remap..."
        reboot
    fi
    echo "### DONE ###"
else
    reboot
fi
SCRIPT

Vagrant.configure("2") do |config|
  wbid = ENV['USER']
  offset = 0

  config.vm.provider "virtualbox" do |v|
    v.gui = false
  end


  ##### DEFINE VM for oob-mgmt-server #####
  config.vm.define "oob-mgmt-server" do |device|
    device.vm.hostname = "oob-mgmt-server"
    device.vm.box = "ubuntu/xenial64"


    device.vm.provider "virtualbox" do |v|
      v.name = "#{wbid}_oob-mgmt-server"
      v.customize ["modifyvm", :id, '--audiocontroller', 'AC97', '--audio', 'Null']
      v.memory = 1024
    end
    device.vm.synced_folder ".", "/vagrant", disabled: true

    # NETWORK INTERFACES
    # link for eth1 --> oob-mgmt-switch:swp1
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net54", auto_config: false , :mac => "44383900005f"


    device.vm.provider "virtualbox" do |vbox|
      vbox.customize ['modifyvm', :id, '--nicpromisc2', 'allow-all']
      vbox.customize ["modifyvm", :id, "--nictype1", "virtio"]
      vbox.customize ["modifyvm", :id, "--nictype2", "virtio"]
    end

    # Fixes "stdin: is not a tty" and "mesg: ttyname failed : Inappropriate ioctl for device"  messages --> https://github.com/mitchellh/vagrant/issues/1673
    device.vm.provision :shell , inline: "(grep -q 'mesg n' /root/.profile 2>/dev/null && sed -i '/mesg n/d' /root/.profile  2>/dev/null && echo 'Ignore the previous error, fixing this now...') || true;"

    # Shorten Boot Process - Applies to Ubuntu Only - remove \"Wait for Network\"
    device.vm.provision :shell , inline: "sed -i 's/sleep [0-9]*/sleep 1/' /etc/init/failsafe.conf || true"

    # Run Any Extra Config
    device.vm.provision :shell , path: "./helper_scripts/config_oob_server.sh"


    extravars = {wbench_hosts: {
        exit02: {ip: "192.168.0.42", mac: "a0:00:00:00:00:42"},
        exit01: {ip: "192.168.0.41", mac: "a0:00:00:00:00:41"},
        spine02: {ip: "192.168.0.22", mac: "a0:00:00:00:00:22"},
        spine01: {ip: "192.168.0.21", mac: "a0:00:00:00:00:21"},
        leaf04: {ip: "192.168.0.14", mac: "a0:00:00:00:00:14"},
        leaf02: {ip: "192.168.0.12", mac: "a0:00:00:00:00:12"},
        leaf03: {ip: "192.168.0.13", mac: "a0:00:00:00:00:13"},
        leaf01: {ip: "192.168.0.11", mac: "a0:00:00:00:00:11"},
        edge01: {ip: "192.168.0.51", mac: "a0:00:00:00:00:51"},
        server01: {ip: "192.168.0.31", mac: "a0:00:00:00:00:31"},
        server03: {ip: "192.168.0.33", mac: "a0:00:00:00:00:33"},
        server02: {ip: "192.168.0.32", mac: "a0:00:00:00:00:32"},
        server04: {ip: "192.168.0.34", mac: "a0:00:00:00:00:34"},
        }}
    device.vm.provision :shell , inline: "sudo apt-get update"
    device.vm.provision :shell , inline: "sudo apt-get install software-properties-common vim lldpd git -y"
    device.vm.provision :shell , inline: "sudo apt-add-repository ppa:ansible/ansible-2.1 -y"
    device.vm.provision :shell , inline: "sudo apt-get update"
    device.vm.provision :shell , inline: "sudo apt-get install ansible -qy"
    device.vm.provision :shell , inline: "git clone https://github.com/cumulusnetworks/cldemo-provision "
    device.vm.provision :shell , inline: "ansible-playbook cldemo-provision/site.yml --extra-vars '#{extravars.to_json}'  --connection=local -i localhost,"


    # Apply the interface re-map
    device.vm.provision "file", source: "./helper_scripts/apply_udev.py", destination: "/home/ubuntu/apply_udev.py"
    device.vm.provision :shell , inline: "chmod 755 /home/ubuntu/apply_udev.py"
    device.vm.provision :shell , inline: "/home/ubuntu/apply_udev.py -a 44:38:39:00:00:5f eth1"
    device.vm.provision :shell , inline: "/home/ubuntu/apply_udev.py -vm --vagrant-name=eth0"
    device.vm.provision :shell , inline: "/home/ubuntu/apply_udev.py -s"
    device.vm.provision :shell , :inline => $script

  end


  ##### DEFINE VM for oob-mgmt-switch #####
  config.vm.define "oob-mgmt-switch" do |device|
    device.vm.hostname = "oob-mgmt-switch"
    device.vm.box = "CumulusCommunity/cumulus-vx"
    device.vm.box_version = "3.2.1"

    device.vm.provider "virtualbox" do |v|
      v.name = "#{wbid}_oob-mgmt-switch"
      v.customize ["modifyvm", :id, '--audiocontroller', 'AC97', '--audio', 'Null']
      v.memory = 512
    end
    device.vm.synced_folder ".", "/vagrant", disabled: true

    # NETWORK INTERFACES
    # link for swp1 --> oob-mgmt-server:eth1
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net54", auto_config: false , :mac => "443839000060"

    # link for swp2 --> server01:eth0
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net42", auto_config: false , :mac => "44383900004b"

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
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net34", auto_config: false , :mac => "44383900003e"

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
      vbox.customize ['modifyvm', :id, '--nicpromisc2', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc3', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc4', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc5', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc6', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc7', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc8', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc9', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc10', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc11', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc12', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc13', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc14', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc15', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc16', 'allow-all']
    end

    # Fixes "stdin: is not a tty" and "mesg: ttyname failed : Inappropriate ioctl for device"  messages --> https://github.com/mitchellh/vagrant/issues/1673
    device.vm.provision :shell , inline: "(grep -q 'mesg n' /root/.profile 2>/dev/null && sed -i '/mesg n/d' /root/.profile  2>/dev/null && echo 'Ignore the previous error, fixing this now...') || true;"

    # Run Any Extra Config
    device.vm.provision :shell , path: "./helper_scripts/config_oob_switch.sh"

    # Apply the interface re-map
    device.vm.provision "file", source: "./helper_scripts/apply_udev.py", destination: "/home/vagrant/apply_udev.py"
    device.vm.provision :shell , inline: "chmod 755 /home/vagrant/apply_udev.py"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:60 swp1"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:4b swp2"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:54 swp3"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:05 swp4"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:56 swp5"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:25 swp6"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:45 swp7"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:34 swp8"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:3e swp9"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:39 swp10"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:69 swp11"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:10 swp12"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:55 swp13"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:48 swp14"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:40 swp15"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -vm -nv"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -s"
    device.vm.provision :shell , :inline => $script

  end


  ##### DEFINE VM for exit02 #####
  config.vm.define "exit02" do |device|
    device.vm.hostname = "exit02"
    device.vm.box = "CumulusCommunity/cumulus-vx"
    device.vm.box_version = "3.2.1"

    device.vm.provider "virtualbox" do |v|
      v.name = "#{wbid}_exit02"
      v.customize ["modifyvm", :id, '--audiocontroller', 'AC97', '--audio', 'Null']
      v.memory = 512
    end
    device.vm.synced_folder ".", "/vagrant", disabled: true

    # NETWORK INTERFACES
    # link for eth0 --> oob-mgmt-switch:swp13
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net48", auto_config: false , :mac => "a00000000042"

    # link for swp1 --> edge01:eth2
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net7", auto_config: false , :mac => "44383900000d"

    # link for swp44 --> internet:swp2
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net39", auto_config: false , :mac => "443839000047"

    # link for swp45 --> exit02:swp46
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net30", auto_config: false , :mac => "443839000037"

    # link for swp46 --> exit02:swp45
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net30", auto_config: false , :mac => "443839000038"

    # link for swp47 --> exit02:swp48
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net33", auto_config: false , :mac => "44383900003c"

    # link for swp48 --> exit02:swp47
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net33", auto_config: false , :mac => "44383900003d"

    # link for swp49 --> exit01:swp49
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net24", auto_config: false , :mac => "44383900002d"

    # link for swp50 --> exit01:swp50
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net14", auto_config: false , :mac => "44383900001a"

    # link for swp51 --> spine01:swp29
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net21", auto_config: false , :mac => "443839000026"

    # link for swp52 --> spine02:swp29
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net53", auto_config: false , :mac => "44383900005d"


    device.vm.provider "virtualbox" do |vbox|
      vbox.customize ['modifyvm', :id, '--nicpromisc2', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc3', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc4', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc5', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc6', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc7', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc8', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc9', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc10', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc11', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc12', 'allow-all']
    end

    # Fixes "stdin: is not a tty" and "mesg: ttyname failed : Inappropriate ioctl for device"  messages --> https://github.com/mitchellh/vagrant/issues/1673
    device.vm.provision :shell , inline: "(grep -q 'mesg n' /root/.profile 2>/dev/null && sed -i '/mesg n/d' /root/.profile  2>/dev/null && echo 'Ignore the previous error, fixing this now...') || true;"

    # Run Any Extra Config
    device.vm.provision :shell , path: "./helper_scripts/config_switch.sh"

    # Apply the interface re-map
    device.vm.provision "file", source: "./helper_scripts/apply_udev.py", destination: "/home/vagrant/apply_udev.py"
    device.vm.provision :shell , inline: "chmod 755 /home/vagrant/apply_udev.py"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a a0:00:00:00:00:42 eth0"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:0d swp1"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:47 swp44"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:37 swp45"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:38 swp46"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:3c swp47"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:3d swp48"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:2d swp49"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:1a swp50"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:26 swp51"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:5d swp52"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -vm "
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -s"
    device.vm.provision :shell , :inline => $script

  end


  ##### DEFINE VM for exit01 #####
  config.vm.define "exit01" do |device|
    device.vm.hostname = "exit01"
    device.vm.box = "CumulusCommunity/cumulus-vx"
    device.vm.box_version = "3.2.1"

    device.vm.provider "virtualbox" do |v|
      v.name = "#{wbid}_exit01"
      v.customize ["modifyvm", :id, '--audiocontroller', 'AC97', '--audio', 'Null']
      v.memory = 512
    end
    device.vm.synced_folder ".", "/vagrant", disabled: true

    # NETWORK INTERFACES
    # link for eth0 --> oob-mgmt-switch:swp12
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net9", auto_config: false , :mac => "a00000000041"

    # link for swp1 --> edge01:eth1
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net46", auto_config: false , :mac => "443839000053"

    # link for swp44 --> internet:swp1
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net5", auto_config: false , :mac => "443839000009"

    # link for swp45 --> exit01:swp46
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net43", auto_config: false , :mac => "44383900004c"

    # link for swp46 --> exit01:swp45
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net43", auto_config: false , :mac => "44383900004d"

    # link for swp47 --> exit01:swp48
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net11", auto_config: false , :mac => "443839000013"

    # link for swp48 --> exit01:swp47
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net11", auto_config: false , :mac => "443839000014"

    # link for swp49 --> exit02:swp49
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net24", auto_config: false , :mac => "44383900002c"

    # link for swp50 --> exit02:swp50
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net14", auto_config: false , :mac => "443839000019"

    # link for swp51 --> spine01:swp30
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net6", auto_config: false , :mac => "44383900000a"

    # link for swp52 --> spine02:swp30
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net56", auto_config: false , :mac => "443839000063"

    device.vm.provider "virtualbox" do |vbox|
      vbox.customize ['modifyvm', :id, '--nicpromisc2', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc3', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc4', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc5', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc6', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc7', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc8', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc9', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc10', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc11', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc12', 'allow-all']
    end

    # Fixes "stdin: is not a tty" and "mesg: ttyname failed : Inappropriate ioctl for device"  messages --> https://github.com/mitchellh/vagrant/issues/1673
    device.vm.provision :shell , inline: "(grep -q 'mesg n' /root/.profile 2>/dev/null && sed -i '/mesg n/d' /root/.profile  2>/dev/null && echo 'Ignore the previous error, fixing this now...') || true;"

    # Run Any Extra Config
    device.vm.provision :shell , path: "./helper_scripts/config_switch.sh"

    # Apply the interface re-map
    device.vm.provision "file", source: "./helper_scripts/apply_udev.py", destination: "/home/vagrant/apply_udev.py"
    device.vm.provision :shell , inline: "chmod 755 /home/vagrant/apply_udev.py"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a a0:00:00:00:00:41 eth0"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:53 swp1"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:09 swp44"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:4c swp45"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:4d swp46"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:13 swp47"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:14 swp48"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:2c swp49"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:19 swp50"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:0a swp51"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:63 swp52"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -vm "
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -s"
    device.vm.provision :shell , :inline => $script

  end


  ##### DEFINE VM for spine02 #####
  config.vm.define "spine02" do |device|
    device.vm.hostname = "spine02"
    device.vm.box = "CumulusCommunity/cumulus-vx"
    device.vm.box_version = "3.2.1"

    device.vm.provider "virtualbox" do |v|
      v.name = "#{wbid}_spine02"
      v.customize ["modifyvm", :id, '--audiocontroller', 'AC97', '--audio', 'Null']
      v.memory = 512
    end
    device.vm.synced_folder ".", "/vagrant", disabled: true

    # NETWORK INTERFACES
    # link for eth0 --> oob-mgmt-switch:swp11
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net59", auto_config: false , :mac => "a00000000022"

    # link for swp1 --> leaf01:swp52
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net23", auto_config: false , :mac => "44383900002b"

    # link for swp2 --> leaf02:swp52
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net58", auto_config: false , :mac => "443839000068"

    # link for swp3 --> leaf03:swp52
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net17", auto_config: false , :mac => "443839000020"

    # link for swp4 --> leaf04:swp52
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net44", auto_config: false , :mac => "44383900004f"

    # link for swp29 --> exit02:swp52
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net53", auto_config: false , :mac => "44383900005e"

    # link for swp30 --> exit01:swp52
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net56", auto_config: false , :mac => "443839000064"

    # link for swp31 --> spine01:swp31
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net45", auto_config: false , :mac => "443839000051"

    # link for swp32 --> spine01:swp32
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net36", auto_config: false , :mac => "443839000042"

    device.vm.provider "virtualbox" do |vbox|
      vbox.customize ['modifyvm', :id, '--nicpromisc2', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc3', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc4', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc5', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc6', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc7', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc8', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc9', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc10', 'allow-all']
    end

    # Fixes "stdin: is not a tty" and "mesg: ttyname failed : Inappropriate ioctl for device"  messages --> https://github.com/mitchellh/vagrant/issues/1673
    device.vm.provision :shell , inline: "(grep -q 'mesg n' /root/.profile 2>/dev/null && sed -i '/mesg n/d' /root/.profile  2>/dev/null && echo 'Ignore the previous error, fixing this now...') || true;"

    # Run Any Extra Config
    device.vm.provision :shell , path: "./helper_scripts/config_switch.sh"

    # Apply the interface re-map
    device.vm.provision "file", source: "./helper_scripts/apply_udev.py", destination: "/home/vagrant/apply_udev.py"
    device.vm.provision :shell , inline: "chmod 755 /home/vagrant/apply_udev.py"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a a0:00:00:00:00:22 eth0"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:2b swp1"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:68 swp2"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:20 swp3"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:4f swp4"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:5e swp29"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:64 swp30"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:51 swp31"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:42 swp32"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -vm "
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -s"
    device.vm.provision :shell , :inline => $script

  end


  ##### DEFINE VM for spine01 #####
  config.vm.define "spine01" do |device|
    device.vm.hostname = "spine01"
    device.vm.box = "CumulusCommunity/cumulus-vx"
    device.vm.box_version = "3.2.1"

    device.vm.provider "virtualbox" do |v|
      v.name = "#{wbid}_spine01"
      v.customize ["modifyvm", :id, '--audiocontroller', 'AC97', '--audio', 'Null']
      v.memory = 512
    end
    device.vm.synced_folder ".", "/vagrant", disabled: true

    # NETWORK INTERFACES
    # link for eth0 --> oob-mgmt-switch:swp10
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net31", auto_config: false , :mac => "a00000000021"

    # link for swp1 --> leaf01:swp51
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net52", auto_config: false , :mac => "44383900005c"

    # link for swp2 --> leaf02:swp51
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net25", auto_config: false , :mac => "44383900002f"

    # link for swp3 --> leaf03:swp51
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net50", auto_config: false , :mac => "443839000058"

    # link for swp4 --> leaf04:swp51
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net37", auto_config: false , :mac => "443839000044"

    # link for swp29 --> exit02:swp51
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net21", auto_config: false , :mac => "443839000027"

    # link for swp30 --> exit01:swp51
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net6", auto_config: false , :mac => "44383900000b"

    # link for swp31 --> spine02:swp31
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net45", auto_config: false , :mac => "443839000050"

    # link for swp32 --> spine02:swp32
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net36", auto_config: false , :mac => "443839000041"

    device.vm.provider "virtualbox" do |vbox|
      vbox.customize ['modifyvm', :id, '--nicpromisc2', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc3', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc4', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc5', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc6', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc7', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc8', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc9', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc10', 'allow-all']
    end

    # Fixes "stdin: is not a tty" and "mesg: ttyname failed : Inappropriate ioctl for device"  messages --> https://github.com/mitchellh/vagrant/issues/1673
    device.vm.provision :shell , inline: "(grep -q 'mesg n' /root/.profile 2>/dev/null && sed -i '/mesg n/d' /root/.profile  2>/dev/null && echo 'Ignore the previous error, fixing this now...') || true;"

    # Run Any Extra Config
    device.vm.provision :shell , path: "./helper_scripts/config_switch.sh"

    # Apply the interface re-map
    device.vm.provision "file", source: "./helper_scripts/apply_udev.py", destination: "/home/vagrant/apply_udev.py"
    device.vm.provision :shell , inline: "chmod 755 /home/vagrant/apply_udev.py"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a a0:00:00:00:00:21 eth0"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:5c swp1"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:2f swp2"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:58 swp3"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:44 swp4"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:27 swp29"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:0b swp30"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:50 swp31"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:41 swp32"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -vm "
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -s"
    device.vm.provision :shell , :inline => $script

  end


  ##### DEFINE VM for leaf04 #####
  config.vm.define "leaf04" do |device|
    device.vm.hostname = "leaf04"
    device.vm.box = "CumulusCommunity/cumulus-vx"
    device.vm.box_version = "3.2.1"

    device.vm.provider "virtualbox" do |v|
      v.name = "#{wbid}_leaf04"
      v.customize ["modifyvm", :id, '--audiocontroller', 'AC97', '--audio', 'Null']
      v.memory = 512
    end
    device.vm.synced_folder ".", "/vagrant", disabled: true

    # NETWORK INTERFACES
    # link for eth0 --> oob-mgmt-switch:swp9
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net34", auto_config: false , :mac => "a00000000014"

    # link for swp1 --> server03:eth2
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net57", auto_config: false , :mac => "443839000066"

    # link for swp2 --> server04:eth2
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net27", auto_config: false , :mac => "443839000033"

    # link for swp45 --> leaf04:swp46
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net16", auto_config: false , :mac => "44383900001d"

    # link for swp46 --> leaf04:swp45
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net16", auto_config: false , :mac => "44383900001e"

    # link for swp47 --> leaf04:swp48
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net32", auto_config: false , :mac => "44383900003a"

    # link for swp48 --> leaf04:swp47
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net32", auto_config: false , :mac => "44383900003b"

    # link for swp49 --> leaf03:swp49
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net29", auto_config: false , :mac => "443839000036"

    # link for swp50 --> leaf03:swp50
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net4", auto_config: false , :mac => "443839000007"

    # link for swp51 --> spine01:swp4
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net37", auto_config: false , :mac => "443839000043"

    # link for swp52 --> spine02:swp4
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net44", auto_config: false , :mac => "44383900004e"

    device.vm.provider "virtualbox" do |vbox|
      vbox.customize ['modifyvm', :id, '--nicpromisc2', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc3', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc4', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc5', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc6', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc7', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc8', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc9', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc10', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc11', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc12', 'allow-all']
    end

    # Fixes "stdin: is not a tty" and "mesg: ttyname failed : Inappropriate ioctl for device"  messages --> https://github.com/mitchellh/vagrant/issues/1673
    device.vm.provision :shell , inline: "(grep -q 'mesg n' /root/.profile 2>/dev/null && sed -i '/mesg n/d' /root/.profile  2>/dev/null && echo 'Ignore the previous error, fixing this now...') || true;"

    # Run Any Extra Config
    device.vm.provision :shell , path: "./helper_scripts/config_switch.sh"

    # Apply the interface re-map
    device.vm.provision "file", source: "./helper_scripts/apply_udev.py", destination: "/home/vagrant/apply_udev.py"
    device.vm.provision :shell , inline: "chmod 755 /home/vagrant/apply_udev.py"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a a0:00:00:00:00:14 eth0"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:66 swp1"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:33 swp2"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:1d swp45"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:1e swp46"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:3a swp47"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:3b swp48"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:36 swp49"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:07 swp50"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:43 swp51"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:4e swp52"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -vm "
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -s"
    device.vm.provision :shell , :inline => $script

  end


  ##### DEFINE VM for leaf02 #####
  config.vm.define "leaf02" do |device|
    device.vm.hostname = "leaf02"
    device.vm.box = "CumulusCommunity/cumulus-vx"
    device.vm.box_version = "3.2.1"

    device.vm.provider "virtualbox" do |v|
      v.name = "#{wbid}_leaf02"
      v.customize ["modifyvm", :id, '--audiocontroller', 'AC97', '--audio', 'Null']
      v.memory = 512
    end
    device.vm.synced_folder ".", "/vagrant", disabled: true

    # NETWORK INTERFACES
    # link for eth0 --> oob-mgmt-switch:swp7
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net38", auto_config: false , :mac => "a00000000012"

    # link for swp1 --> server01:eth2
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net13", auto_config: false , :mac => "443839000018"

    # link for swp2 --> server02:eth2
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net15", auto_config: false , :mac => "44383900001c"

    # link for swp45 --> leaf02:swp46
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net8", auto_config: false , :mac => "44383900000e"

    # link for swp46 --> leaf02:swp45
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net8", auto_config: false , :mac => "44383900000f"

    # link for swp47 --> leaf02:swp48
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net55", auto_config: false , :mac => "443839000061"

    # link for swp48 --> leaf02:swp47
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net55", auto_config: false , :mac => "443839000062"

    # link for swp49 --> leaf01:swp49
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net10", auto_config: false , :mac => "443839000012"

    # link for swp50 --> leaf01:swp50
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net1", auto_config: false , :mac => "443839000002"

    # link for swp51 --> spine01:swp2
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net25", auto_config: false , :mac => "44383900002e"

    # link for swp52 --> spine02:swp2
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net58", auto_config: false , :mac => "443839000067"

    device.vm.provider "virtualbox" do |vbox|
      vbox.customize ['modifyvm', :id, '--nicpromisc2', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc3', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc4', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc5', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc6', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc7', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc8', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc9', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc10', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc11', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc12', 'allow-all']
    end

    # Fixes "stdin: is not a tty" and "mesg: ttyname failed : Inappropriate ioctl for device"  messages --> https://github.com/mitchellh/vagrant/issues/1673
    device.vm.provision :shell , inline: "(grep -q 'mesg n' /root/.profile 2>/dev/null && sed -i '/mesg n/d' /root/.profile  2>/dev/null && echo 'Ignore the previous error, fixing this now...') || true;"

    # Run Any Extra Config
    device.vm.provision :shell , path: "./helper_scripts/config_switch.sh"

    # Apply the interface re-map
    device.vm.provision "file", source: "./helper_scripts/apply_udev.py", destination: "/home/vagrant/apply_udev.py"
    device.vm.provision :shell , inline: "chmod 755 /home/vagrant/apply_udev.py"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a a0:00:00:00:00:12 eth0"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:18 swp1"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:1c swp2"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:0e swp45"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:0f swp46"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:61 swp47"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:62 swp48"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:12 swp49"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:02 swp50"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:2e swp51"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:67 swp52"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -vm "
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -s"
    device.vm.provision :shell , :inline => $script

  end


  ##### DEFINE VM for leaf03 #####
  config.vm.define "leaf03" do |device|
    device.vm.hostname = "leaf03"
    device.vm.box = "CumulusCommunity/cumulus-vx"
    device.vm.box_version = "3.2.1"

    device.vm.provider "virtualbox" do |v|
      v.name = "#{wbid}_leaf03"
      v.customize ["modifyvm", :id, '--audiocontroller', 'AC97', '--audio', 'Null']
      v.memory = 512
    end
    device.vm.synced_folder ".", "/vagrant", disabled: true

    # NETWORK INTERFACES
    # link for eth0 --> oob-mgmt-switch:swp8
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net28", auto_config: false , :mac => "a00000000013"

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
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net51", auto_config: false , :mac => "44383900005a"

    # link for swp49 --> leaf04:swp49
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net29", auto_config: false , :mac => "443839000035"

    # link for swp50 --> leaf04:swp50
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net4", auto_config: false , :mac => "443839000006"

    # link for swp51 --> spine01:swp3
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net50", auto_config: false , :mac => "443839000057"

    # link for swp52 --> spine02:swp3
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net17", auto_config: false , :mac => "44383900001f"

    device.vm.provider "virtualbox" do |vbox|
      vbox.customize ['modifyvm', :id, '--nicpromisc2', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc3', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc4', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc5', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc6', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc7', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc8', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc9', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc10', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc11', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc12', 'allow-all']
    end

    # Fixes "stdin: is not a tty" and "mesg: ttyname failed : Inappropriate ioctl for device"  messages --> https://github.com/mitchellh/vagrant/issues/1673
    device.vm.provision :shell , inline: "(grep -q 'mesg n' /root/.profile 2>/dev/null && sed -i '/mesg n/d' /root/.profile  2>/dev/null && echo 'Ignore the previous error, fixing this now...') || true;"

    # Run Any Extra Config
    device.vm.provision :shell , path: "./helper_scripts/config_switch.sh"

    # Apply the interface re-map
    device.vm.provision "file", source: "./helper_scripts/apply_udev.py", destination: "/home/vagrant/apply_udev.py"
    device.vm.provision :shell , inline: "chmod 755 /home/vagrant/apply_udev.py"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a a0:00:00:00:00:13 eth0"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:29 swp1"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:24 swp2"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:30 swp45"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:31 swp46"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:59 swp47"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:5a swp48"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:35 swp49"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:06 swp50"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:57 swp51"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:1f swp52"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -vm "
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -s"
    device.vm.provision :shell , :inline => $script

  end


  ##### DEFINE VM for leaf01 #####
  config.vm.define "leaf01" do |device|
    device.vm.hostname = "leaf01"
    device.vm.box = "CumulusCommunity/cumulus-vx"
    device.vm.box_version = "3.2.1"

    device.vm.provider "virtualbox" do |v|
      v.name = "#{wbid}_leaf01"
      v.customize ["modifyvm", :id, '--audiocontroller', 'AC97', '--audio', 'Null']
      v.memory = 512
    end
    device.vm.synced_folder ".", "/vagrant", disabled: true

    # NETWORK INTERFACES
    # link for eth0 --> oob-mgmt-switch:swp6
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net20", auto_config: false , :mac => "a00000000011"

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
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net41", auto_config: false , :mac => "44383900004a"

    # link for swp49 --> leaf02:swp49
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net10", auto_config: false , :mac => "443839000011"

    # link for swp50 --> leaf02:swp50
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net1", auto_config: false , :mac => "443839000001"

    # link for swp51 --> spine01:swp1
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net52", auto_config: false , :mac => "44383900005b"

    # link for swp52 --> spine02:swp1
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net23", auto_config: false , :mac => "44383900002a"

    device.vm.provider "virtualbox" do |vbox|
      vbox.customize ['modifyvm', :id, '--nicpromisc2', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc3', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc4', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc5', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc6', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc7', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc8', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc9', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc10', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc11', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc12', 'allow-all']
    end

    # Fixes "stdin: is not a tty" and "mesg: ttyname failed : Inappropriate ioctl for device"  messages --> https://github.com/mitchellh/vagrant/issues/1673
    device.vm.provision :shell , inline: "(grep -q 'mesg n' /root/.profile 2>/dev/null && sed -i '/mesg n/d' /root/.profile  2>/dev/null && echo 'Ignore the previous error, fixing this now...') || true;"

    # Run Any Extra Config
    device.vm.provision :shell , path: "./helper_scripts/config_switch.sh"

    # Apply the interface re-map
    device.vm.provision "file", source: "./helper_scripts/apply_udev.py", destination: "/home/vagrant/apply_udev.py"
    device.vm.provision :shell , inline: "chmod 755 /home/vagrant/apply_udev.py"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a a0:00:00:00:00:11 eth0"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:04 swp1"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:16 swp2"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:21 swp45"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:22 swp46"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:49 swp47"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:4a swp48"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:11 swp49"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:01 swp50"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:5b swp51"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:2a swp52"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -vm "
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -s"
    device.vm.provision :shell , :inline => $script

  end


  ##### DEFINE VM for edge01 #####
  config.vm.define "edge01" do |device|
    device.vm.hostname = "edge01"
    device.vm.box = "ubuntu/xenial64"

    device.vm.provider "virtualbox" do |v|
      v.name = "#{wbid}_edge01"
      v.customize ["modifyvm", :id, '--audiocontroller', 'AC97', '--audio', 'Null']
      v.memory = 512
    end
    device.vm.synced_folder ".", "/vagrant", disabled: true

    # NETWORK INTERFACES
    # link for eth0 --> oob-mgmt-switch:swp14
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net40", auto_config: false , :mac => "a00000000051"

    # link for eth1 --> exit01:swp1
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net46", auto_config: false , :mac => "443839000052"

    # link for eth2 --> exit02:swp1
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net7", auto_config: false , :mac => "44383900000c"

    device.vm.provider "virtualbox" do |vbox|
      vbox.customize ['modifyvm', :id, '--nicpromisc2', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc3', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc4', 'allow-all']
    end

    # Fixes "stdin: is not a tty" and "mesg: ttyname failed : Inappropriate ioctl for device"  messages --> https://github.com/mitchellh/vagrant/issues/1673
    device.vm.provision :shell , inline: "(grep -q 'mesg n' /root/.profile 2>/dev/null && sed -i '/mesg n/d' /root/.profile  2>/dev/null && echo 'Ignore the previous error, fixing this now...') || true;"

    # Shorten Boot Process - Applies to Ubuntu Only - remove \"Wait for Network\"
    device.vm.provision :shell , inline: "sed -i 's/sleep [0-9]*/sleep 1/' /etc/init/failsafe.conf || true"

    # Run Any Extra Config
    device.vm.provision :shell , path: "./helper_scripts/config_server.sh"

    # Apply the interface re-map
    device.vm.provision "file", source: "./helper_scripts/apply_udev.py", destination: "/home/ubuntu/apply_udev.py"
    device.vm.provision :shell , inline: "chmod 755 /home/ubuntu/apply_udev.py"
    device.vm.provision :shell , inline: "/home/ubuntu/apply_udev.py -a a0:00:00:00:00:51 eth0"
    device.vm.provision :shell , inline: "/home/ubuntu/apply_udev.py -a 44:38:39:00:00:52 eth1"
    device.vm.provision :shell , inline: "/home/ubuntu/apply_udev.py -a 44:38:39:00:00:0c eth2"
    device.vm.provision :shell , inline: "/home/ubuntu/apply_udev.py -vm "
    device.vm.provision :shell , inline: "/home/ubuntu/apply_udev.py -s"
    device.vm.provision :shell , :inline => $script

  end


  ##### DEFINE VM for server01 #####
  config.vm.define "server01" do |device|
    device.vm.hostname = "server01"
    device.vm.box = "ubuntu/xenial64"

    device.vm.provider "virtualbox" do |v|
      v.name = "#{wbid}_server01"
      v.customize ["modifyvm", :id, '--audiocontroller', 'AC97', '--audio', 'Null']
      v.memory = 512
    end
    device.vm.synced_folder ".", "/vagrant", disabled: true

    # NETWORK INTERFACES
    # link for eth0 --> oob-mgmt-switch:swp2
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net42", auto_config: false , :mac => "a00000000031"

    # link for eth1 --> leaf01:swp1
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net2", auto_config: false , :mac => "443839000003"

    # link for eth2 --> leaf02:swp1
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net13", auto_config: false , :mac => "443839000017"

    device.vm.provider "virtualbox" do |vbox|
      vbox.customize ['modifyvm', :id, '--nicpromisc2', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc3', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc4', 'allow-all']
    end

    # Fixes "stdin: is not a tty" and "mesg: ttyname failed : Inappropriate ioctl for device"  messages --> https://github.com/mitchellh/vagrant/issues/1673
    device.vm.provision :shell , inline: "(grep -q 'mesg n' /root/.profile 2>/dev/null && sed -i '/mesg n/d' /root/.profile  2>/dev/null && echo 'Ignore the previous error, fixing this now...') || true;"

    # Shorten Boot Process - Applies to Ubuntu Only - remove \"Wait for Network\"
    device.vm.provision :shell , inline: "sed -i 's/sleep [0-9]*/sleep 1/' /etc/init/failsafe.conf || true"

    # Run Any Extra Config
    device.vm.provision :shell , path: "./helper_scripts/config_server.sh"

    # Apply the interface re-map
    device.vm.provision "file", source: "./helper_scripts/apply_udev.py", destination: "/home/ubuntu/apply_udev.py"
    device.vm.provision :shell , inline: "chmod 755 /home/ubuntu/apply_udev.py"
    device.vm.provision :shell , inline: "/home/ubuntu/apply_udev.py -a a0:00:00:00:00:31 eth0"
    device.vm.provision :shell , inline: "/home/ubuntu/apply_udev.py -a 44:38:39:00:00:03 eth1"
    device.vm.provision :shell , inline: "/home/ubuntu/apply_udev.py -a 44:38:39:00:00:17 eth2"
    device.vm.provision :shell , inline: "/home/ubuntu/apply_udev.py -vm "
    device.vm.provision :shell , inline: "/home/ubuntu/apply_udev.py -s"
    device.vm.provision :shell , :inline => $script

  end


  ##### DEFINE VM for server03 #####
  config.vm.define "server03" do |device|
    device.vm.hostname = "server03"
    device.vm.box = "ubuntu/xenial64"

    device.vm.provider "virtualbox" do |v|
      v.name = "#{wbid}_server03"
      v.customize ["modifyvm", :id, '--audiocontroller', 'AC97', '--audio', 'Null']
      v.memory = 512
    end
    device.vm.synced_folder ".", "/vagrant", disabled: true

    # NETWORK INTERFACES
    # link for eth0 --> oob-mgmt-switch:swp4
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net3", auto_config: false , :mac => "a00000000033"

    # link for eth1 --> leaf03:swp1
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net22", auto_config: false , :mac => "443839000028"

    # link for eth2 --> leaf04:swp1
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net57", auto_config: false , :mac => "443839000065"

    device.vm.provider "virtualbox" do |vbox|
      vbox.customize ['modifyvm', :id, '--nicpromisc2', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc3', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc4', 'allow-all']
    end

    # Fixes "stdin: is not a tty" and "mesg: ttyname failed : Inappropriate ioctl for device"  messages --> https://github.com/mitchellh/vagrant/issues/1673
    device.vm.provision :shell , inline: "(grep -q 'mesg n' /root/.profile 2>/dev/null && sed -i '/mesg n/d' /root/.profile  2>/dev/null && echo 'Ignore the previous error, fixing this now...') || true;"

    # Shorten Boot Process - Applies to Ubuntu Only - remove \"Wait for Network\"
    device.vm.provision :shell , inline: "sed -i 's/sleep [0-9]*/sleep 1/' /etc/init/failsafe.conf || true"

    # Run Any Extra Config
    device.vm.provision :shell , path: "./helper_scripts/config_server.sh"



    # Apply the interface re-map
    device.vm.provision "file", source: "./helper_scripts/apply_udev.py", destination: "/home/ubuntu/apply_udev.py"
    device.vm.provision :shell , inline: "chmod 755 /home/ubuntu/apply_udev.py"
    device.vm.provision :shell , inline: "/home/ubuntu/apply_udev.py -a a0:00:00:00:00:33 eth0"
    device.vm.provision :shell , inline: "/home/ubuntu/apply_udev.py -a 44:38:39:00:00:28 eth1"
    device.vm.provision :shell , inline: "/home/ubuntu/apply_udev.py -a 44:38:39:00:00:65 eth2"


    device.vm.provision :shell , inline: "/home/ubuntu/apply_udev.py -vm "
    device.vm.provision :shell , inline: "/home/ubuntu/apply_udev.py -s"
    device.vm.provision :shell , :inline => $script

  end


  ##### DEFINE VM for server02 #####
  config.vm.define "server02" do |device|
    device.vm.hostname = "server02"
    device.vm.box = "ubuntu/xenial64"

    device.vm.provider "virtualbox" do |v|
      v.name = "#{wbid}_server02"
      v.customize ["modifyvm", :id, '--audiocontroller', 'AC97', '--audio', 'Null']
      v.memory = 512
    end
    device.vm.synced_folder ".", "/vagrant", disabled: true

    # NETWORK INTERFACES
    # link for eth0 --> oob-mgmt-switch:swp3
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net47", auto_config: false , :mac => "a00000000032"

    # link for eth1 --> leaf01:swp2
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net12", auto_config: false , :mac => "443839000015"

    # link for eth2 --> leaf02:swp2
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net15", auto_config: false , :mac => "44383900001b"

    device.vm.provider "virtualbox" do |vbox|
      vbox.customize ['modifyvm', :id, '--nicpromisc2', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc3', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc4', 'allow-all']
    end

    # Fixes "stdin: is not a tty" and "mesg: ttyname failed : Inappropriate ioctl for device"  messages --> https://github.com/mitchellh/vagrant/issues/1673
    device.vm.provision :shell , inline: "(grep -q 'mesg n' /root/.profile 2>/dev/null && sed -i '/mesg n/d' /root/.profile  2>/dev/null && echo 'Ignore the previous error, fixing this now...') || true;"

    # Shorten Boot Process - Applies to Ubuntu Only - remove \"Wait for Network\"
    device.vm.provision :shell , inline: "sed -i 's/sleep [0-9]*/sleep 1/' /etc/init/failsafe.conf || true"

    # Run Any Extra Config
    device.vm.provision :shell , path: "./helper_scripts/config_server.sh"

    # Apply the interface re-map
    device.vm.provision "file", source: "./helper_scripts/apply_udev.py", destination: "/home/ubuntu/apply_udev.py"
    device.vm.provision :shell , inline: "chmod 755 /home/ubuntu/apply_udev.py"
    device.vm.provision :shell , inline: "/home/ubuntu/apply_udev.py -a a0:00:00:00:00:32 eth0"
    device.vm.provision :shell , inline: "/home/ubuntu/apply_udev.py -a 44:38:39:00:00:15 eth1"
    device.vm.provision :shell , inline: "/home/ubuntu/apply_udev.py -a 44:38:39:00:00:1b eth2"
    device.vm.provision :shell , inline: "/home/ubuntu/apply_udev.py -vm "
    device.vm.provision :shell , inline: "/home/ubuntu/apply_udev.py -s"
    device.vm.provision :shell , :inline => $script

  end


  ##### DEFINE VM for server04 #####
  config.vm.define "server04" do |device|
    device.vm.hostname = "server04"
    device.vm.box = "ubuntu/xenial64"


    device.vm.provider "virtualbox" do |v|
      v.name = "#{wbid}_server04"
      v.customize ["modifyvm", :id, '--audiocontroller', 'AC97', '--audio', 'Null']
      v.memory = 512
    end
    device.vm.synced_folder ".", "/vagrant", disabled: true

    # NETWORK INTERFACES
    # link for eth0 --> oob-mgmt-switch:swp5
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net49", auto_config: false , :mac => "a00000000034"

    # link for eth1 --> leaf03:swp2
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net19", auto_config: false , :mac => "443839000023"

    # link for eth2 --> leaf04:swp2
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net27", auto_config: false , :mac => "443839000032"

    device.vm.provider "virtualbox" do |vbox|
      vbox.customize ['modifyvm', :id, '--nicpromisc2', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc3', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc4', 'allow-all']
    end

    # Fixes "stdin: is not a tty" and "mesg: ttyname failed : Inappropriate ioctl for device"  messages --> https://github.com/mitchellh/vagrant/issues/1673
    device.vm.provision :shell , inline: "(grep -q 'mesg n' /root/.profile 2>/dev/null && sed -i '/mesg n/d' /root/.profile  2>/dev/null && echo 'Ignore the previous error, fixing this now...') || true;"

    # Shorten Boot Process - Applies to Ubuntu Only - remove \"Wait for Network\"
    device.vm.provision :shell , inline: "sed -i 's/sleep [0-9]*/sleep 1/' /etc/init/failsafe.conf || true"

    # Run Any Extra Config
    device.vm.provision :shell , path: "./helper_scripts/config_server.sh"

    # Apply the interface re-map
    device.vm.provision "file", source: "./helper_scripts/apply_udev.py", destination: "/home/ubuntu/apply_udev.py"
    device.vm.provision :shell , inline: "chmod 755 /home/ubuntu/apply_udev.py"
    device.vm.provision :shell , inline: "/home/ubuntu/apply_udev.py -a a0:00:00:00:00:34 eth0"
    device.vm.provision :shell , inline: "/home/ubuntu/apply_udev.py -a 44:38:39:00:00:23 eth1"
    device.vm.provision :shell , inline: "/home/ubuntu/apply_udev.py -a 44:38:39:00:00:32 eth2"
    device.vm.provision :shell , inline: "/home/ubuntu/apply_udev.py -vm "
    device.vm.provision :shell , inline: "/home/ubuntu/apply_udev.py -s"
    device.vm.provision :shell , :inline => $script

  end


  ##### DEFINE VM for internet #####
  config.vm.define "internet" do |device|
    device.vm.hostname = "internet"
    device.vm.box = "CumulusCommunity/cumulus-vx"
    device.vm.box_version = "3.2.1"

    device.vm.provider "virtualbox" do |v|
      v.name = "#{wbid}_internet"
      v.customize ["modifyvm", :id, '--audiocontroller', 'AC97', '--audio', 'Null']
      v.memory = 512
    end
    device.vm.synced_folder ".", "/vagrant", disabled: true

    # NETWORK INTERFACES
    # link for eth0 --> oob-mgmt-switch:swp15
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net35", auto_config: false , :mac => "44383900003f"

    # link for swp1 --> exit01:swp44
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net5", auto_config: false , :mac => "443839000008"

    # link for swp2 --> exit02:swp44
    device.vm.network "private_network", virtualbox__intnet: "#{wbid}_net39", auto_config: false , :mac => "443839000046"

    device.vm.provider "virtualbox" do |vbox|
      vbox.customize ['modifyvm', :id, '--nicpromisc2', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc3', 'allow-all']
      vbox.customize ['modifyvm', :id, '--nicpromisc4', 'allow-all']
      # delete strange phantom NICs in cumulus-vx VirtualBox images
      vbox.customize ['modifyvm', :id, '--nic9', 'none']
      vbox.customize ['modifyvm', :id, '--nic10', 'none']
    end

    # Fixes "stdin: is not a tty" and "mesg: ttyname failed : Inappropriate ioctl for device"  messages --> https://github.com/mitchellh/vagrant/issues/1673
    device.vm.provision :shell , inline: "(grep -q 'mesg n' /root/.profile 2>/dev/null && sed -i '/mesg n/d' /root/.profile  2>/dev/null && echo 'Ignore the previous error, fixing this now...') || true;"

    # Run Any Extra Config
    device.vm.provision :shell , path: "./helper_scripts/config_internet.sh"

    # Apply the interface re-map
    device.vm.provision "file", source: "./helper_scripts/apply_udev.py", destination: "/home/vagrant/apply_udev.py"
    device.vm.provision :shell , inline: "chmod 755 /home/vagrant/apply_udev.py"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:3f eth0"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:08 swp1"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -a 44:38:39:00:00:46 swp2"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -vm --vagrant-name=swp48"
    device.vm.provision :shell , inline: "/home/vagrant/apply_udev.py -s"
    device.vm.provision :shell , :inline => $script

  end

end
