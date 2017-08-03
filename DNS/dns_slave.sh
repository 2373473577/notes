#!/bin/bash

#定义域名服务器地址
read -p "请输入您的主DNS服务器IP地址：" -t 30  NS_IP
read -p "请输入您的从DNS服务器域名地址："  -t 30 NS_DOMAIN


#安装DNS包
yum -y install bind


#修改主配置文件
cat >/etc/named.conf <<EOF
include "/etc/dx.cfg";
include "/etc/wt.cfg";

options {
	listen-on port 53 { 127.0.0.1; any; };
	directory 	"/var/named";
	dump-file 	"/var/named/data/cache_dump.db";
	statistics-file "/var/named/data/named_stats.txt";
	memstatistics-file "/var/named/data/named_mem_stats.txt";
	allow-query     { localhost; any; };
	recursion yes;
	dnssec-enable no;
	dnssec-validation no;
	dnssec-lookaside auto;
	bindkeys-file "/etc/named.iscdlv.key";
	managed-keys-directory "/var/named/dynamic";
	pid-file "/run/named/named.pid";
	session-keyfile "/run/named/session.key";
};
logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};
view "dxclient" {
        match-clients { dx; };
        zone "." IN {
                type hint;
                file "named.ca";
        };
        zone "${NS_DOMAIN}" IN {
                type slave;
                masters { ${NS_IP}; };
                file "slaves/dx.${NS_DOMAIN}.zone";
        };
include "/etc/named.rfc1912.zones";
};
view "wtclient" {
        match-clients { wt; };
        zone "." IN {
                type hint;
                file "named.ca";
        };
        zone "${NS_DOMAIN}" IN {
                type slave;
                masters { ${NS_IP}; };
                file "slaves/wt.${NS_DOMAIN}.zone";
        };
include "/etc/named.rfc1912.zones";
};
view "other" {
        match-clients { any;};
         zone "." IN {
                type hint;
                file "named.ca";
        };
        zone "${NS_DOMAIN}" IN {
		type slave;                                        
                masters { ${NS_IP}; };
                file "slaves/other.${NS_DOMAIN}.zone";
        };
include "/etc/named.rfc1912.zones";
};
include "/etc/named.root.key";
EOF

cat >/etc/dx.cfg <<EOF
acl "dx" {
        172.25.16.11;
};
EOF

cat >/etc/wt.cfg <<EOF
acl "wt" {
        172.25.16.12;
};
EOF


systemctl restart named
systemctl enable named

