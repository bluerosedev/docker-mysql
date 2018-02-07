#!/bin/sh

. /usr/local/bin/env_secrets_expand.sh

MYSQL_ROOT_PASSWORD=$(cat ${MYSQL_ROOT_PASSWORD_FILE})

# Adapted from https://github.com/woxxy/MySQL-backup-to-Amazon-S3

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M")
DATABASE='--all-databases'
PERIOD=${1-hour}

echo "Selected period: $PERIOD."


#tmp path.
TMP_PATH=/tmp

echo "Starting backing up the database to a file..."

# dump all databases
mysqldump --quick --user=root --password=${MYSQL_ROOT_PASSWORD} ${DATABASE} > ${TMP_PATH}/dump_${TIMESTAMP}.sql

echo "Done backing up the database to a file."
echo "Starting compression..."

tar czf ${TMP_PATH}/${TIMESTAMP}.tar.gz -C ${TMP_PATH} dump_${TIMESTAMP}.sql

echo "Done compressing the backup file."

# we want at least two backups, two months, two weeks, and two days
echo "Removing old backup (2 ${PERIOD}s ago)..."
s3cmd del --recursive s3://${S3_BUCKET}/${S3_PATH}/previous_${PERIOD}/
echo "Old backup removed."

# with Digital Ocean spaces mv seems to be a copy

echo "Moving the backup from past $PERIOD to another folder..."
s3cmd mv --recursive s3://${S3_BUCKET}/${S3_PATH}/${PERIOD}/ s3://${S3_BUCKET}/${S3_PATH}/previous_${PERIOD}/
s3cmd del --recursive s3://${S3_BUCKET}/${S3_PATH}/${PERIOD}/
echo "Past backup moved."

# upload all databases
echo "Uploading the new backup..."
s3cmd put -f ${TMP_PATH}/${TIMESTAMP}.tar.gz s3://${S3_BUCKET}/${S3_PATH}/${PERIOD}/
echo "New backup uploaded."

echo "Removing the cache files..."
# remove databases dump
rm ${TMP_PATH}/dump_${TIMESTAMP}.sql
rm ${TMP_PATH}/${TIMESTAMP}.tar.gz
echo "Files removed."
echo "All done."
