FROM debian:jessie

RUN export DEBIAN_FRONTEND='noninteractive' && \
    apt-get update -qq && \
    apt-get install -qqy --no-install-recommends vsftpd && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*

RUN mkdir /etc/vsftpd
COPY vsftpd.conf /etc/vsftpd/vsftpd.conf

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

EXPOSE 21/tcp

ENTRYPOINT ["/entrypoint.sh"]
