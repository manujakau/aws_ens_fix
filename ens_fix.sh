#!/bin/bash
yum install kernel-devel-$(uname -r) gcc git patch rpm-build wget
wget https://github.com/amzn/amzn-drivers/archive/master.zip
unzip master.zip
cd amzn-drivers-master/kernel/linux/ena
make
cp ena.ko /lib/modules/$(uname -r)/                       
insmod ena.ko                                             
depmod                                                    
echo 'add_drivers+=" ena "' >> /etc/dracut.conf.d/ena.conf
dracut -f -v                                              
lsinitrd /boot/initramfs-xxx.el6.x86_64.img | grep ena.ko

yum upgrade kernel && reboot

yum install -y http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
yum install dkms -y

VER=$( grep ^VERSION /root/amzn-drivers-master/kernel/linux/rpm/Makefile | cut -d' ' -f2 )
sudo cp -a /root/amzn-drivers-master /usr/src/amzn-drivers-${VER}

cat > /usr/src/amzn-drivers-${VER}/dkms.conf <<EOM
PACKAGE_NAME="ena"
PACKAGE_VERSION="$VER"
CLEAN="make -C kernel/linux/ena clean"
MAKE="make -C kernel/linux/ena/ BUILD_KERNEL=\${kernelver}"
BUILT_MODULE_NAME[0]="ena"
BUILT_MODULE_LOCATION="kernel/linux/ena"
DEST_MODULE_LOCATION[0]="/updates"
DEST_MODULE_NAME[0]="ena"
AUTOINSTALL="yes"
EOM

dkms add -m amzn-drivers -v $VER
yum install kernel-devel-$(uname -r) -y
dkms build -m amzn-drivers -v $VER
dkms install -m amzn-drivers -v $VER

echo "net.ifnames=0" >> /boot/grub/menu.lst