#!/bin/bash

# default env variables

S3_BUCKET="${S3_BUCKET-no}"
S3_PATH="${S3_PATH-no}"
S3_ACCESS_KEY="${S3_ACCESS_KEY-no}"
S3_SECRET_KEY="${S3_SECRET_KEY-no}"
RESTORE_FROM="${RESTORE_FROM-no}"
S3_ENCRYPTION_KEY="${S3_ENCRYPTION_KEY-no}"

# determine whether we should register backup jobs

[ "${S3_BUCKET}" != 'no' ] && \
[ "${S3_PATH}" != 'no' ] && \
[ "${S3_ACCESS_KEY}" != 'no' ] && \
[ "${S3_SECRET_KEY}" != 'no' ] &&
[ "${S3_ENCRYPTION_KEY}" != 'no' ]

BACKUP=$?

if [ "${BACKUP}" -eq 0 ]; then

    echo "access_key=${S3_ACCESS_KEY}" >> /root/.s3cfg
    echo "secret_key=${S3_SECRET_KEY}" >> /root/.s3cfg
    echo "gpg_passphrase=${S3_ENCRYPTION_KEY}" >> /root/.s3cfg

    echo "Installing cron jobs for backup"

    # hourly backup
    echo "0 * * * * root supervisorctl start backup-hourly" > /etc/cron.d/backup-hourly

    # daily MySQL backup to S3 (not on first day of month or sundays)
    echo "0 3 2-31 * 1-6 root supervisorctl start backup-daily" > /etc/cron.d/backup-daily

    # weekly MySQL backup to S3 (on sundays, but not the first day of the month)
    echo "0 3 2-31 * 0 root supervisorctl start backup-weekly" > /etc/cron.d/backup-weekly

    # monthly MySQL backup to S3
    echo "0 3 1 * * root supervisorctl start backup-monthly" > /etc/cron.d/backup-monthly

    echo "Cron jobs installed"

fi

# determine if we should restore from backup

[ "${BACKUP}" -eq 0 ] && [ "${RESTORE_FROM}" != 'no' ]

if [ "$?" -eq 0 ]; then

    LATEST_BACKUP=$(s3cmd ls s3://${S3_BUCKET}/${S3_PATH}/${RESTORE_FROM}/ | tail -1 | awk '{print $4}')

    echo "Attempting to restore from ${RESTORE_FROM} backup"

    if [ ${RESTORE_FROM+x} != '' ] && [ ${LATEST_BACKUP+x} != '' ] && [ $(ls /docker-entrypoint-initdb.d/ | wc -l) -eq 0 ]; then

        echo "Backup found: ${LATEST_BACKUP}"

        s3cmd get ${LATEST_BACKUP} /tmp/backup.tar.gz
        tar -xvf /tmp/backup.tar.gz -C /docker-entrypoint-initdb.d/
        rm /tmp/backup.tar.gz

        echo "Backup installed"

    fi

fi

# start mysql

/usr/local/bin/docker-entrypoint.sh mysqld