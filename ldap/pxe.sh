#!/bin/bash

echo "/usr/sbin/setenforce 0" >>  /etc/rc.local
echo "/usr/sbin/iptables -F" >> /etc/rc.local
chmod +x /etc/rc.d/rc.local
source  /etc/rc.local

sed -i 's/ONBOOT.*/ONBOOT=no/' /etc/sysconfig/network-scripts/ifcfg-eth0
