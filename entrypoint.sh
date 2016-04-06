#!/bin/sh

sed -i "s/^pasv_address=.*/pasv_address=$PASV_ADDRESS/" /etc/vsftpd/vsftpd.conf
sed -i "s/^pasv_min_port=.*/pasv_min_port=$PASV_MIN_PORT/" /etc/vsftpd/vsftpd.conf
sed -i "s/^pasv_max_port=.*/pasv_max_port=$PASV_MAX_PORT/" /etc/vsftpd/vsftpd.conf

if [ -n "$USER" ] && [ -n "$PASSWD" ]; then
  adduser -h /var/lib/ftp/ -D -H $USER
  echo "seedbox:$PASSWD" | chpasswd
fi

if [ -n "$SSL_DATA" ]; then
  echo "ssl_enable=YES" >> /etc/vsftpd/vsftpd.conf
  echo "force_local_data_ssl=$SSL_DATA" >> /etc/vsftpd/vsftpd.conf
  echo "force_local_logins_ssl=YES" >> /etc/vsftpd/vsftpd.conf
  echo "rsa_cert_file=/etc/vsftpd/$SSL_CERT" >> /etc/vsftpd/vsftpd.conf
  echo "rsa_private_key_file=/etc/vsftpd/$SSL_KEY" >> /etc/vsftpd/vsftpd.conf
fi

exec vsftpd /etc/vsftpd/vsftpd.conf
