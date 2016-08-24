#!/usr/bin/env bash

sed -i "s/^pasv_address=.*/pasv_address=$PASV_ADDRESS/" /etc/vsftpd/vsftpd.conf
sed -i "s/^pasv_min_port=.*/pasv_min_port=$PASV_MIN_PORT/" /etc/vsftpd/vsftpd.conf
sed -i "s/^pasv_max_port=.*/pasv_max_port=$PASV_MAX_PORT/" /etc/vsftpd/vsftpd.conf

if [ -n "$USER" ] && [ -n "$PASSWD" ]; then
    printf "User: %s\nPass: %s\n" "$USER" "$PASSWD"
    useradd -d /srv/ftp -M $USER
    #echo "$USER:$PASSWD" | chpasswd -e
    echo "$USER:$PASSWD" | chpasswd
    echo "Changed password for '$USER' to '$PASSWD'."
fi

if [ $SSL = "YES" ]; then
    echo "ssl_enable=YES" >> /etc/vsftpd/vsftpd.conf
    echo "force_local_logins_ssl=YES" >> /etc/vsftpd/vsftpd.conf
    if [ -n "$SSL_DATA" ]; then
        echo "force_local_data_ssl=$SSL_DATA" >> /etc/vsftpd/vsftpd.conf
    fi
    echo "rsa_cert_file=/etc/vsftpd/vsftpd.cert.pem" >> /etc/vsftpd/vsftpd.conf
    echo "rsa_private_key_file=/etc/vsftpd/vsftpd.key.pem" >> /etc/vsftpd/vsftpd.conf
fi

#ln -sf /dev/stdout $LOG_FILE

# Trap code borrowed from https://github.com/panubo/docker-vsftpd/blob/master/entry.sh
function vsftpd_stop() {
  echo "Received SIGINT or SIGTERM. Shutting down vsftpd"
  # Get PID
  pid=$(cat /var/run/vsftpd/vsftpd.pid)
  # Set TERM
  kill -SIGTERM "${pid}"
  # Wait for exit
  wait "${pid}"
  # All done.
  echo "Done"
}

if [ "$1" == "vsftpd" ]; then
  trap vsftpd_stop SIGINT SIGTERM
  echo "Running $@"
  $@ &
  pid="$!"
  echo "${pid}" > /var/run/vsftpd/vsftpd.pid
  wait "${pid}" && exit $?
else
  exec "$@"
fi
