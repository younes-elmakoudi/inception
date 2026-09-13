#!/bin/bash
set -e

FTP_PASSWORD=$(cat "$FTP_PASSWORD_FILE")

if ! id "$FTP_USER" &>/dev/null; then
    useradd -d /var/www/html -s /bin/bash "$FTP_USER"
    echo "${FTP_USER}:${FTP_PASSWORD}" | chpasswd
    chown -R "$FTP_USER":"$FTP_USER" /var/www/html
fi

CONTAINER_IP=$(hostname -i)
echo "pasv_address=${CONTAINER_IP}" >> /etc/vsftpd.conf

exec vsftpd /etc/vsftpd.conf