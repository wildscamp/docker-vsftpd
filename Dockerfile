FROM alpine:3.3

RUN apk add --update vsftpd
RUN rm -rf /var/cache/apk/*

EXPOSE 21/tcp

#ENTRYPOINT ["vsftpd","/etc/vsftpd/vsftpd.conf"]
