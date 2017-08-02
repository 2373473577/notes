#!/bin/bash

echo "/usr/sbin/setenforce 0" >>  /etc/rc.local 
echo "/usr/sbin/iptables -F" >> /etc/rc.local 
chmod +x /etc/rc.d/rc.local
source  /etc/rc.local 

sed -i 's/ONBOOT.*/ONBOOT=no/' /etc/sysconfig/network-scripts/ifcfg-eth0
echo "GATEWAY=192.168.0.10" >>/etc/sysconfig/network-scripts/ifcfg-eth1
systemctl restart network

hostnamectl set-hostname pxe

yum -y install dhcp

cat >/etc/dhcp/dhcpd.conf <<EOF
allow booting;
allow bootp;

option domain-name "pod0.example.com";
option domain-name-servers 172.25.254.254;
default-lease-time 600;
max-lease-time 7200;
log-facility local7;

subnet 192.168.0.0 netmask 255.255.255.0 {
  range 192.168.0.50 192.168.0.100;
  option domain-name-servers 172.25.254.254;
  option domain-name "pod0.example.com";
  option routers 192.168.0.10;
  option broadcast-address 192.168.0.255;
  default-lease-time 600;
  max-lease-time 7200;
  next-server 192.168.0.16;
  filename "pxelinux.0";
}

class "foo" {
  match if substring (option vendor-class-identifier, 0, 4) = "SUNW";
}

shared-network 224-29 {
  subnet 10.17.224.0 netmask 255.255.255.0 {
    option routers rtr-224.example.org;
  }
  subnet 10.0.29.0 netmask 255.255.255.0 {
    option routers rtr-29.example.org;
  }
  pool {
    allow members of "foo";
    range 10.17.224.10 10.17.224.250;
  }
  pool {
    deny members of "foo";
    range 10.0.29.10 10.0.29.230;
  }
}
EOF

systemctl restart dhcpd
systemctl enable dhcpd

yum -y install xinetd tftp-server
sed -i '/disable/s/yes/no/g' /etc/xinetd.d/tftp
systemctl restart xinetd
systemctl enable xinetd

yum -y install syslinux
cp /usr/share/syslinux/pxelinux.0 /var/lib/tftpboot/

mkdir /var/lib/tftpboot/pxelinux.cfg

touch /var/lib/tftpboot/pxelinux.cfg/default
cat >/var/lib/tftpboot/pxelinux.cfg/default <<EOF
default vesamenu.c32
timeout 60
display boot.msg
menu background splash.png
menu title Welcome to Global Learning Services Setup!

label local
        menu label Boot from ^local drive
        menu default
        localboot 0xffff

label install
        menu label Install rhel7
        kernel vmlinuz
        append initrd=initrd.img  ks=http://192.168.0.16/myks.cfg
EOF

mount -t nfs 172.25.254.250:/content /mnt/
mount -o  loop /mnt/rhel7.1/x86_64/isos/rhel-server-7.1-x86_64-dvd.iso  /media
cp /media/isolinux/* /var/lib/tftpboot/

yum -y install httpd
cat >>/var/www/html/myks.cfg <<EOF
#version=RHEL7
# System authorization information
auth --enableshadow --passalgo=sha512
# Reboot after installation 
reboot # 装完系统之后是否重启
# Use network installation
url --url="http://192.168.0.16/dvd/"  # 网络安装介质所在位置
# Use graphical install
#graphical 
text # 采用字符界面安装
# Firewall configuration
firewall --enabled --service=ssh  # 防火墙的配置
firstboot --disable
ignoredisk --only-use=vda
# Keyboard layouts
# old format: keyboard us
# new format:
keyboard --vckeymap=us --xlayouts='us' # 键盘的配置
# System language 
lang en_US.UTF-8 # 语言制式的设置
# Network information
network  --bootproto=dhcp # 网络设置
network  --hostname=localhost.localdomain
#repo --name="Server-ResilientStorage" --baseurl=http://download.eng.bos.redhat.com/rel-eng/latest-RHEL-7/compose/Server/x86_64/os//addons/ResilientStorage
# Root password
rootpw --iscrypted nope 
# SELinux configuration
selinux --disabled
# System services
services --disabled="kdump,rhsmcertd" --enabled="network,sshd,rsyslog,ovirt-guest-agent,chronyd"
# System timezone
timezone Asia/Shanghai --isUtc
# System bootloader configuration
bootloader --append="console=tty0 crashkernel=auto" --location=mbr --timeout=1 --boot-drive=vda 
# 设置boot loader安装选项 --append指定内核参数 --location 设定引导记录的位置
# Clear the Master Boot Record
zerombr # 清空MBR
# Partition clearing information
clearpart --all --initlabel # 清空分区信息
# Disk partitioning information
part / --fstype="xfs" --ondisk=vda --size=6144 # 设置根目录的分区情况
%post # 装完系统后执行脚本部分
echo "redhat" | passwd --stdin root
useradd carol
echo "redhat" | passwd --stdin carol
# workaround anaconda requirements
%end

%packages # 需要安装的软件包
@core
%end
EOF

chown apache. /var/www/html/myks.cfg

mkdir /var/www/html/dvd
mount /mnt/rhel7.1/x86_64/isos/rhel-server-7.1-x86_64-dvd.iso /var/www/html/dvd
systemctl restart httpd
systemctl enable httpd


