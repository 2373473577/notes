#!/bin/bash

setenforce 0
iptables -F

yum install openldap openldap-clients nss-pam-ldapd -y

authconfig --enableldap --enableldapauth --ldapserver=servera.pod16.example.com --ldapbasedn="dc=example,dc=org" --enableldaptls --ldaploadcacert=http://servera.pod16.example.com/ca.crt  --update

yum -y install autofs
echo >/etc/auto.master <<EOF
/ldapuser /etc/auto.ldap
EOF

echo >/etc/auto.ldap <<EOF
*       -rw,soft,intr 172.25.16.10:/ldapuser/&
EOF

service autofs start

yum install vsftpd -y
systemctl start vsftpd

yum -y install httpd
yum install wget -y

wget -r ftp://172.25.254.250/notes/project/UP200/UP200_ldap-master/openldap/pkg/
cd 172.25.254.250/notes/project/UP200/UP200_ldap-master/openldap/pkg/
rpm -ivh apr-util-ldap-1.5.2-6.el7.x86_64.rpm mod_ldap-2.4.6-31.el7.x86_64.rpm

wget http://servera.pod16.example.com/ca.crt -O /etc/httpd/ca.crt

echo >/etc/httpd/conf.d/www.ldapuser.com.conf <<EOF
LDAPTrustedGlobalCert CA_BASE64 /etc/httpd/ca.crt
<VirtualHost *:80>
        ServerName www.ldapuser.com
        DocumentRoot /var/www/ldapuser.com
        <Directory "/var/www/ldapuser.com">
                AuthName ldap
                AuthType basic
                AuthBasicProvider ldap
                AuthLDAPUrl "ldap://servera.pod1.example.com/dc=example,dc=org" TLS
                Require valid-user
        </Directory>
</VirtualHost>
EOF

service httpd restart
mkdir -p /var/www/ldapuser.com
echo "welcome to ldapserver from serverb1" > /var/www/ldapuser.com/index.html





























