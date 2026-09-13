FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    php-fpm \
    php-mysqli \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/adminer

RUN curl -o index.php -sSL https://www.adminer.org/latest.php

COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf

EXPOSE 9001

ENTRYPOINT ["php-fpm8.2", "-F"]