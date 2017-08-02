#!/bin/bash

#磁盘分区
fdisk -l /dev/sdb
dd if=/dev/zero of=/dev/sdb bs=500 count=1

#非交互式磁盘分区
cat >/fdisk.txt <<EOF
n
p
1

7G
a
w
EOF

fdisk -cu /dev/sdb </fdisk.txt
#------------------------------------------------------------
mkfs.ext4 /dev/sdb1
mkdir  /mnt/usb
mount  /dev/sdb1  /mnt/usb

mount -t nfs 172.25.254.250:/content  /media/
mkdir /dvd
mount  /media/rhel6.5/x86_64/isos/rhel-server-6.5-x86_64-dvd.iso  /dvd

mkdir -p /dev/shm/usb

#配置yum源
rm  -f  /etc/yum.repos.d/*
cat  >/etc/yum.repos.d/iso.repo <<EOF
[iso]
name=hejun
baseurl=file:///dvd
enabled=1
gpgcheck=0
EOF

yum -y install filesystem bash coreutils passwd shadow-utils openssh-clients rpm yum net-tools bind-utils vim-enhanced findutils lvm2 util-linux-ng --installroot=/dev/shm/usb/
cp -arv /dev/shm/usb/* /mnt/usb/

cp /boot/vmlinuz-2.6.32-431.el6.x86_64 /mnt/usb/boot/
cp /boot/initramfs-2.6.32-431.el6.x86_64.img /mnt/usb/boot/
cp -arv /lib/modules/2.6.32-431.el6.x86_64/ /mnt/usb/lib/modules/

rpm -ivh ftp://192.168.0.254/notes/project/software/grub-0.97-77.el6.x86_64.rpm --root=/mnt/usb/ --nodeps --force
grub-install --root-directory=/mnt/usb/  --recheck  /dev/sdb
cp /boot/grub/grub.conf /mnt/usb/boot/grub/

usbid=`blkid /dev/sdb1 |awk -F \" '{print $2}'`
export usbid

cat >/mnt/usb/boot/grub/grub.conf <<EOF
default=0
timeout=5
splashimage=/boot/grub/splash.xpm.gz
hiddenmenu
title My USB System from hejun
        root (hd0,0)
        kernel /boot/vmlinuz-2.6.32-431.el6.x86_64 ro root=UUID=$usbid selinux=0
        initrd /boot/initramfs-2.6.32-431.el6.x86_64.img
EOF

cp /etc/skel/.bash* /mnt/usb/root/

cp /etc/sysconfig/network-scripts/ifcfg-eth0 /mnt/usb/etc/sysconfig/network-scripts/

cat >/mnt/usb/etc/fstab <<EOF
UUID=$usbid / ext4 defaults 0 0
sysfs                   /sys                    sysfs   defaults        0 0
proc                    /proc                   proc    defaults        0 0
tmpfs                   /dev/shm                tmpfs   defaults        0 0
devpts                  /dev/pts                devpts  gid=5,mode=620  0 0
EOF

#密码123
cat /mnt/usb/etc/shadow |sed  '/root/s/*/$1$1Q1sQ\/$xlwH4uHQ.6ruQ5AjP0vYw0/'

sync
reboot


