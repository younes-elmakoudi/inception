#!/bin/bash
set -e

DB_PASSWORD=$(cat "$MYSQL_PASSWORD_FILE")
WP_ADMIN_PASSWORD=$(cat "$WP_ADMIN_PASSWORD_FILE")
WP_USER_PASSWORD=$(cat "$WP_USER_PASSWORD_FILE")

echo "[init-wp] Waiting for MariaDB to be reachable..."
until mysqladmin ping -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$DB_PASSWORD" --silent 2>/dev/null; do
    sleep 1
done
echo "[init-wp] MariaDB is up"

if [ ! -f "/var/www/html/wp-config.php" ]; then
    echo "[init-wp] Fresh install detected, provisioning WordPress"

    wp core download --allow-root

    wp config create \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${DB_PASSWORD}" \
        --dbhost="${MYSQL_HOST}" \
        --allow-root

    wp core install \
        --url="https://${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --allow-root

    wp user create "${WP_USER}" "${WP_USER_EMAIL}" \
        --role=author \
        --user_pass="${WP_USER_PASSWORD}" \
        --allow-root
        wp config set WP_REDIS_HOST redis --allow-root

    echo "[init-wp] Waiting for Redis to be reachable..."
    until bash -c "echo > /dev/tcp/redis/6379" 2>/dev/null; do
        sleep 1
    done
    echo "[init-wp] Redis is up"

    wp plugin install redis-cache --activate --allow-root
    wp redis enable --allow-root

    echo "[init-wp] WordPress provisioned"
fi

chown -R www-data:www-data /var/www/html

exec php-fpm8.2 -F