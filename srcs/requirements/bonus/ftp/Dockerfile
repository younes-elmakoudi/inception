FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    vsftpd \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /var/run/vsftpd/empty

COPY conf/vsftpd.conf /etc/vsftpd.conf
COPY tools/init-ftp.sh /usr/local/bin/init-ftp.sh
RUN chmod +x /usr/local/bin/init-ftp.sh

EXPOSE 21 21100-21110

ENTRYPOINT ["/usr/local/bin/init-ftp.sh"]