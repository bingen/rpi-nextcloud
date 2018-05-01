#!/bin/bash

# Script is launched from outside, called from setup.sh in docker home
# server parent, as we need to wait for both Openldap and Nextcloud to be
# up for the Let's Encrypt server to connect to Nextcloud instance and
# verify domain ownership.

# Let's encrypt
mkdir -p /var/www/html/.well-known
chown www-data:www-data /var/www/html/.well-known
certbot certonly --webroot -w /var/www/html -d ${NEXTCLOUD_SERVER_NAME}.${NEXTCLOUD_DOMAIN} --email ${ADMIN_EMAIL} --agree-tos
if [ $? -eq 0 ]; then
    sed -i 's/ssl_certificate \/etc\/nginx\/ssl\/nextcloud.crt;/ssl_certificate \/etc\/letsencrypt\/live\/'${NEXTCLOUD_SERVER_NAME}.${NEXTCLOUD_DOMAIN}'\/fullchain.pem;/g' /etc/nginx/sites-available/default;
    sed -i 's/ssl_certificate_key \/etc\/nginx\/ssl\/nextcloud.key;/ssl_certificate_key \/etc\/letsencrypt\/live\/'${NEXTCLOUD_SERVER_NAME}.${NEXTCLOUD_DOMAIN}'\/privkey.pem;/g' /etc/nginx/sites-available/default;
    service nginx reload;
    # cron
    echo "#!/bin/sh" > /etc/cron.monthly/letsencrypt;
    echo "" >> /etc/cron.monthly/letsencrypt;
    echo "certbot renew" >> /etc/cron.monthly/letsencrypt;
fi
