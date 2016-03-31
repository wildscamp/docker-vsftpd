FROM alpine:3.3

RUN apk add --update vsftpd
RUN rm -rf /var/cache/apk/*

RUN touch /var/log/vsftpd.log
RUN chmod 600 /var/log/vsftpd.log

COPY vsftpd.conf /etc/vsftpd/vsftpd.conf

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

EXPOSE 21/tcp

ENTRYPOINT ["/entrypoint.sh"]
