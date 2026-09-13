#!/bin/bash
IP="$1"
ACTION="$2"

if [ "$ACTION" = "ban" ]; then
    echo "deny ${IP};" >> /etc/nginx/blocklist.d/blocked_ips.conf
elif [ "$ACTION" = "unban" ]; then
    sed -i "/deny ${IP};/d" /etc/nginx/blocklist.d/blocked_ips.conf
fi

docker exec nginx nginx -s reload