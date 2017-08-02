#!/bin/bash

while :
do
        read -p "请输入要删除的LDAP User[输入q则退出]:" user
        if [ "$user" = "q" ] ;then
           exit
        fi
ldapdelete -x -D "cn=Manager,dc=example,dc=org" -w redhat "uid=$user,ou=People,dc=example,dc=org"&& echo "删除用户$user成功!"
done
