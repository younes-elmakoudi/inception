FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    fail2ban \
    docker.io \
    && rm -rf /var/lib/apt/lists/*

RUN rm -f /etc/fail2ban/jail.d/*.conf

COPY conf/jail.local /etc/fail2ban/jail.local
COPY conf/wordpress-auth.conf /etc/fail2ban/filter.d/wordpress-auth.conf
COPY conf/nginx-reload.conf /etc/fail2ban/action.d/nginx-reload.conf
COPY conf/nginx-reload.sh /etc/fail2ban/action.d/nginx-reload.sh

RUN chmod +x /etc/fail2ban/action.d/nginx-reload.sh

ENTRYPOINT ["fail2ban-server", "-f", "-x"]