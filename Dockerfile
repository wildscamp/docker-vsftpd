FROM alpine:3.3

RUN apk add --update vsftpd
RUN rm -rf /var/cache/apk/*

COPY vsftpd.conf /etc/vsftpd/vsftpd.conf

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

EXPOSE 21/tcp

ENTRYPOINT ["vsftpd","/etc/vsftpd/vsftpd.conf"]
