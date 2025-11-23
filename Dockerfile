# syntax=docker/dockerfile:1
# check=skip=SecretsUsedInArgOrEnv

FROM debian:bookworm-slim

# Install dependencies in a single layer
RUN apt-get update -qq && apt-get install -qqy --no-install-recommends \
        libpam-pwdfile \
        openssl \
        vsftpd \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Configuration environment variables
ENV \
    DEFAULT_USER_CONFIG=/etc/vsftpd/default_user.conf \
    LOG_FILE=/var/log/vsftpd.log \
    PAM_FILE=/etc/pam.d/vsftpd \
    PASSWD_FILE=/etc/vsftpd/vsftpd.passwd \
    SSL=false \
    USER_CONFIG_DIR=/etc/vsftpd/vusers

# Create directories and configure PAM in a single layer
RUN mkdir -p /etc/vsftpd ${USER_CONFIG_DIR} /var/run/vsftpd/empty /home/virtual \
    && echo "auth required pam_pwdfile.so pwdfile ${PASSWD_FILE}" > ${PAM_FILE} \
    && echo "account required pam_permit.so" >> ${PAM_FILE}

# Copy configuration files
COPY --chmod=644 *.conf /etc/vsftpd/

# Copy and set permissions for entrypoint in one step
COPY --chmod=755 entrypoint.sh /entrypoint.sh

WORKDIR /etc/vsftpd

EXPOSE 20/tcp
EXPOSE 21/tcp
EXPOSE 30000-30009/tcp

ENTRYPOINT ["/entrypoint.sh"]
CMD ["vsftpd", "/etc/vsftpd/vsftpd.conf"]
