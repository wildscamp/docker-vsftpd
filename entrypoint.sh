#!/bin/sh

sed -i "s/^pasv_address=.*/pasv_address=$PASV_ADDRESS/" /etc/vsftpd/vsftpd.conf
sed -i "s/^pasv_min_port=.*/pasv_address=$PASV_MIN_PORT/" /etc/vsftpd/vsftpd.conf
sed -i "s/^pasv_max_port=.*/pasv_address=$PASV_MAX_PORT/" /etc/vsftpd/vsftpd.conf

exec vsftpd /etc/vsftpd/vsftpd.conf
