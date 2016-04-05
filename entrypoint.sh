#!/bin/sh

sed -i "s/^pasv_address=.*/pasv_address=$PASV_ADDRESS/" /etc/vsftpd/vsftpd.conf
sed -i "s/^pasv_min_port=.*/pasv_min_port=$PASV_MIN_PORT/" /etc/vsftpd/vsftpd.conf
sed -i "s/^pasv_max_port=.*/pasv_max_port=$PASV_MAX_PORT/" /etc/vsftpd/vsftpd.conf

if [ -z "$USER" ] && [ -z "$PASSWD" ]; then
  adduser -h /var/lib/ftp/ -D -H $USER
  echo "seedbox:$PASSWD" | chpasswd
fi

exec vsftpd /etc/vsftpd/vsftpd.conf
