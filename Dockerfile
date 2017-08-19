FROM bingen/rpi-nginx-php

ARG NEXTCLOUD_VERSION
ARG NEXTCLOUD_DATA_PATH
ARG NEXTCLOUD_BACKUP_PATH

RUN apt-get update && \
    apt-get install -y wget bzip2 vim rsync mariadb-client php5-ldap cron anacron

# Change upload-limits and -sizes
RUN sudo sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 2048M/g" /etc/php5/fpm/php.ini && \
    sudo sed -i "s/post_max_size = 8M/post_max_size =root123  2048M/g" /etc/php5/fpm/php.ini && \
    sudo echo 'default_charset = "UTF-8"' >> /etc/php5/fpm/php.ini && \
    echo "upload_tmp_dir = ${NEXTCLOUD_DATA_PATH}" >> /etc/php5/fpm/php.ini && \
    echo "extension = apc.so" >> /etc/php5/fpm/php.ini && \
    echo "apc.enabled = 1" >> /etc/php5/fpm/php.ini && \
    echo "apc.include_once_override = 0" >> /etc/php5/fpm/php.ini && \
    echo "apc.shm_size = 256" >> /etc/php5/fpm/php.ini

# now add our hand-written nginx-default-configuration which makes use of all the stuff so far prepared
COPY default /etc/nginx/sites-available/default

# Create the data-directory where NEXTCLOUD can store its stuff
RUN mkdir -p "${NEXTCLOUD_DATA_PATH}" && \
    chown -R www-data:www-data "${NEXTCLOUD_DATA_PATH}" && \
    mkdir -p "${NEXTCLOUD_BACKUP_PATH}"

# finally, download NEXTCLOUD and extract it
RUN mkdir -p /var/www
WORKDIR /var/www

RUN wget https://download.nextcloud.com/server/releases/${NEXTCLOUD_VERSION}.tar.bz2 && \
    tar xvf ${NEXTCLOUD_VERSION}.tar.bz2 && \
    chown -R www-data:www-data nextcloud && \
    rm ${NEXTCLOUD_VERSION}.tar.bz2

WORKDIR /
COPY docker-entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
COPY backup.sh /etc/cron.daily/backup
RUN chmod +x /etc/cron.daily/backup

#VOLUME ${NEXTCLOUD_DATA_PATH}
#VOLUME ${NEXTCLOUD_BACKUP_PATH}

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD service php5-fpm start && nginx
#CMD ["service", "php5-fpm", "start", "&&", "nginx"]