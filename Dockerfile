FROM debian:jessie

RUN export DEBIAN_FRONTEND='noninteractive' && \
    apt-get update -qq && \
    apt-get install -qqy --no-install-recommends vsftpd openssl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*

ENV LOG_FILE=/var/log/vsftpd.log \
    SSL=false \
    PAM_FILE=/etc/vsftpd/vsftpd.passwd

RUN mkdir -p /etc/vsftpd /var/run/vsftpd/empty && \
    echo "auth required pam_pwdfile.so pwdfile ${PAM_FILE}" > /etc/pam.d/vsftpd && \
    echo "account required pam_permit.so" >> /etc/pam.d/vsftpd

COPY vsftpd.conf /etc/vsftpd/vsftpd.conf

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

EXPOSE 21/tcp

ENTRYPOINT ["/entrypoint.sh"]
CMD ["vsftpd", "/etc/vsftpd/vsftpd.conf"]
