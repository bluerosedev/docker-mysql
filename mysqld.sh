#!/bin/bash

. /usr/local/bin/env_secrets_expand.sh

# default env variables

S3_BUCKET="${S3_BUCKET-no}"
S3_PATH="${S3_PATH-no}"
AWS_ACCESS_KEY="${AWS_ACCESS_KEY-no}"
AWS_SECRET_KEY="${AWS_SECRET_KEY-no}"
RESTORE_FROM="${RESTORE_FROM-no}"
AWS_REGION="${AWS_REGION-no}"
BACKUP="${BACKUP-no}"

# determine whether we should register backup jobs

[ "${S3_BUCKET}" != 'no' ] && \
[ "${S3_PATH}" != 'no' ] && \
[ "${AWS_ACCESS_KEY}" != 'no' ] && \
[ "${AWS_SECRET_KEY}" != 'no' ] && \
[ "${AWS_REGION}" != 'no' ] && \

S3_CONFIGURED=$?

if [ "${S3_CONFIGURED}" -eq 0 ]; then

    dockerize --template /root/.s3cfg.tmpl:/root/.s3cfg echo "Configuring s3cmd"

    if [ "${BACKUP}" == "yes" ]; then

        echo "Configuring backup"

        # hourly backup
        echo "0 * * * * root supervisorctl start backup-hourly" > /etc/cron.d/backup-hourly

        # daily MySQL backup to S3 (not on first day of month or sundays)
        echo "0 3 2-31 * 1-6 root supervisorctl start backup-daily" > /etc/cron.d/backup-daily

        # weekly MySQL backup to S3 (on sundays, but not the first day of the month)
        echo "0 3 2-31 * 0 root supervisorctl start backup-weekly" > /etc/cron.d/backup-weekly

        # monthly MySQL backup to S3
        echo "0 3 1 * * root supervisorctl start backup-monthly" > /etc/cron.d/backup-monthly

        echo "Backup cron jobs installed"

    fi

    if [ "${RESTORE_FROM}" != 'no' ]; then

        LATEST_BACKUP=$(s3cmd ls s3://${S3_BUCKET}/${S3_PATH}/${RESTORE_FROM}/ | tail -1 | awk '{print $4}')

        echo "Attempting to restore from ${RESTORE_FROM} backup"

        if [ ${RESTORE_FROM} != 'no' ] && [ ${LATEST_BACKUP+x} != '' ] && [ $(ls /docker-entrypoint-initdb.d/ | wc -l) -eq 0 ]; then

            echo "Backup found: ${LATEST_BACKUP}"

            s3cmd get ${LATEST_BACKUP} /tmp/backup.tar.gz
            tar -xvf /tmp/backup.tar.gz -C /docker-entrypoint-initdb.d/
            rm /tmp/backup.tar.gz

            echo "Backup installed"

        fi

    fi

fi

# start mysql

/usr/local/bin/docker-entrypoint.sh mysqld
