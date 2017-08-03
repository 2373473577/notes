#!/bin/bash

#定义域名服务器地址
read -p "请输入您的DNS服务器IP地址：" -t 30  NS_IP
read -p "请输入您的DNS服务器域名地址："  -t 30 NS_DOMAIN


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
                type master;
                file "dx.${NS_DOMAIN}.zone";
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
                type master;
                file "wt.${NS_DOMAIN}.zone";
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
                type master;
                file "other.${NS_DOMAIN}.zone";
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

cd /var/named/
cat >dx.${NS_DOMAIN}.zone <<EOF
\$TTL 1D
@       IN SOA  ns1.${NS_DOMAIN}. nsmail.${NS_DOMAIN}. (
                                        10       ; serial
                                        1D      ; refresh
                                        1H      ; retry
                                        1W      ; expire
                                        3H )    ; minimum
@       NS      ns1.${NS_DOMAIN}.
ns1     A       $NS_IP
www     A       192.168.11.1
EOF

cat >wt.${NS_DOMAIN}.zone <<EOF
\$TTL 1D
@       IN SOA  ns1.${NS_DOMAIN}. nsmail.${NS_DOMAIN}. (
                                        10       ; serial
                                        1D      ; refresh
                                        1H      ; retry
                                        1W      ; expire
                                        3H )    ; minimum
@       NS      ns1.${NS_DOMAIN}.
ns1     A       $NS_IP
www     A       22.21.1.1
EOF

cat >other.${NS_DOMAIN}.zone <<EOF
\$TTL 1D
@       IN SOA  ns1.${NS_DOMAIN}. nsmail.${NS_DOMAIN}. (
                                        10       ; serial
                                        1D      ; refresh
                                        1H      ; retry
                                        1W      ; expire
                                        3H )    ; minimum
@       NS      ns1.${NS_DOMAIN}.
ns1     A       $NS_IP
www     A       1.1.1.1
EOF

chgrp named wt.${NS_DOMAIN}.zone dx.${NS_DOMAIN}.zone other.${NS_DOMAIN}.zone 

systemctl restart named
systemctl enable named

