#!/usr/bin/env bash
set -e

. /usr/local/bin/env_secrets_expand.sh

# SIGUSR1-handler
my_handler() {
  echo "my_handler"
}

# SIGTERM-handler
term_handler() {

    S3_BUCKET="${S3_BUCKET-no}"
    S3_PATH="${S3_PATH-no}"
    AWS_ACCESS_KEY="${AWS_ACCESS_KEY-no}"
    AWS_SECRET_KEY="${AWS_SECRET_KEY-no}"
    AWS_REGION="${AWS_REGION-no}"
    BACKUP="${BACKUP-no}"
    RESTORE_FROM="${RESTORE_FROM-no}"

    # determine whether we should register backup jobs

    [ "${S3_BUCKET}" != 'no' ] && \
    [ "${S3_PATH}" != 'no' ] && \
    [ "${AWS_ACCESS_KEY}" != 'no' ] && \
    [ "${AWS_SECRET_KEY}" != 'no' ] && \
    [ "${AWS_REGION}" != 'no' ] && \
    [ "${BACKUP}" != 'no' ] && \
    [ "${RESTORE_FROM}" != 'no' ]

    if [ "$?" -eq 0 ]; then
        echo "Backing up database on shutdown: ${RESTORE_FROM}"
        /usr/local/bin/mysqltos3 hourly
    fi

  exit 143; # 128 + 15 -- SIGTERM
}

# setup handlers
# on callback, kill the last background process, which is `tail -f /dev/null` and execute the specified handler
trap 'kill ${!}; my_handler' SIGUSR1
trap 'kill ${!}; term_handler' SIGTERM

# wait forever
while true
do
  tail -f /dev/null & wait ${!}
done
