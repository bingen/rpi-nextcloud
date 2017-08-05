#!/bin/bash

# TODO: mail
#Mail vars
#MAIL_FROM="postmaster@{DOMAIN}"
#MAIL_TO=
#MAIL_SUBJECT='Nextcloud backup report'

function mail() {
    #mutt -e "set from=${MAIL_FROM}" -s "${MAIL_SUBJECT}" -- "${MAIL_TO}" <<< $1
    echo $1
}

ERROR=""

# Backup Nextcloud root folder
echo "Copying Nextcloud"
rsync -auv --delete --ignore-errors /var/www/nextcloud/  ${NEXTCLOUD_BACKUP_PATH}/nextcloud > /tmp/backup_nextcloud-`date +%Y%m%d_%H%M`.log 2>&1
if [ $? != 0 ]
then
    tmp="Error copying Nextcloud.\n"
    echo $tmp
    ERROR="$ERROR $tmp"
fi

# Backup Nextcloud Data folder
echo "Copying Data"
rsync -auv --delete --ignore-errors ${NEXTCLOUD_DATA_PATH}  ${NEXTCLOUD_BACKUP_PATH}/data > /tmp/backup_nextcloud_data-`date +%Y%m%d_%H%M`.log 2>&1
if [ $? != 0 ]
then
    tmp="Error copying Data.\n"
    echo $tmp
    ERROR="$ERROR $tmp"
fi

# Backup Mysql DB
DB_PWD=`grep dbpassword /var/www/nextcloud/config/config.php | awk -F "'" '{ print $4 }'`
DB_BACKUP_FILE=${NEXTCLOUD_BACKUP_PATH}/nextcloud-sqlbkp_`date +"%Y%m%d"`.sql
mysqldump --lock-tables -u ${NEXTCLOUD_DB_USER} -p${DB_PWD} -h ${DB_HOST} ${NEXTCLOUD_DB_NAME} > ${DB_BACKUP_FILE}
if [ $? != 0 ]
then
    tmp="Error backing Nextcloud DB up\n"
    echo $tmp
    ERROR="$ERROR $tmp"
fi
# Compress Mysql Backup
gzip ${DB_BACKUP_FILE}
# Remove backups older than 5 days
find ${NEXTCLOUD_BACKUP_PATH} -mtime +5 -type f -name "nextcloud-sqlbkp*" -delete

if [ -z "$ERROR" ]
then
    mail "Everything went right"
else
    mail "$ERROR"
fi

exit 0
