#!/bin/bash
set -e

DB_PASSWORD=$(cat "$MYSQL_PASSWORD_FILE")
DB_ROOT_PASSWORD=$(cat "$MYSQL_ROOT_PASSWORD_FILE")

mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld

if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "[init-db] First run detected, initializing data directory"
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql \
        --auth-root-authentication-method=normal > /dev/null

    mysqld --user=mysql --datadir=/var/lib/mysql --bind-address=127.0.0.1 &
    TMP_PID=$!

    until mysqladmin ping -h 127.0.0.1 --silent 2>/dev/null; do
        sleep 1
    done

    mysql -u root -h 127.0.0.1 <<-EOSQL
    CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
    CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
    GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
    ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
    FLUSH PRIVILEGES;
EOSQL

    mysqladmin -u root -p"${DB_ROOT_PASSWORD}" -h 127.0.0.1 shutdown
    wait "$TMP_PID"
    echo "[init-db] Initialization complete"
fi

echo "[init-db] Starting mariadbd"
exec mysqld --user=mysql --datadir=/var/lib/mysql