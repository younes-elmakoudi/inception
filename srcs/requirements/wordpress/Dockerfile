FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    php-fpm \
    php-mysqli \
    php-curl \
    php-gd \
    php-xml \
    php-mbstring \
    php-zip \
    curl \
    default-mysql-client \
    && rm -rf /var/lib/apt/lists/*

RUN curl -o /usr/local/bin/wp -sSL \
    https://github.com/wp-cli/wp-cli/releases/latest/download/wp-cli.phar \
    && chmod +x /usr/local/bin/wp

WORKDIR /var/www/html

COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY tools/init-wp.sh /usr/local/bin/init-wp.sh
RUN chmod +x /usr/local/bin/init-wp.sh

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/init-wp.sh"]