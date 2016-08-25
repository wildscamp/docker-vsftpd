FROM debian:jessie

RUN export DEBIAN_FRONTEND='noninteractive' && \
    apt-get update -qq && \
    apt-get install -qqy --no-install-recommends vsftpd libpam-pwdfile apache2-utils openssl vim && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*

ENV LOG_FILE=/var/log/vsftpd.log \
    SSL=false \
    PAM_FILE=/etc/pam.d/vsftpd \
    PASSWD_FILE=/etc/vsftpd/vsftpd.passwd \
    DEFAULT_USER_CONFIG=/etc/vsftpd/default_user.conf \
    USER_CONFIG_DIR=/etc/vsftpd/vusers

RUN mkdir -p /etc/vsftpd $USER_CONFIG_DIR /var/run/vsftpd/empty /home/virtual && \
    echo "auth required pam_pwdfile.so pwdfile ${PASSWD_FILE}" > $PAM_FILE && \
    echo "account required pam_permit.so" >> $PAM_FILE

COPY *.conf /etc/vsftpd/

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

WORKDIR /etc/vsftpd

EXPOSE 21/tcp

ENTRYPOINT ["/entrypoint.sh"]
CMD ["vsftpd", "/etc/vsftpd/vsftpd.conf"]
