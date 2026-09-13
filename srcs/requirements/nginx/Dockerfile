FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx \
    openssl \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/nginx/ssl /etc/nginx/blocklist.d \
    && touch /etc/nginx/blocklist.d/blocked_ips.conf

COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY tools/setup-ssl.sh /usr/local/bin/setup-ssl.sh
RUN chmod +x /usr/local/bin/setup-ssl.sh

EXPOSE 443

ENTRYPOINT ["/usr/local/bin/setup-ssl.sh"]