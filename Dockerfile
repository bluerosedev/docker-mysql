FROM mysql

RUN apt-get update && \
    apt-get install -y \
        cron \
        less \
        python-setuptools \
        supervisor \
        vim \
        wget && \
    wget http://downloads.sourceforge.net/project/s3tools/s3cmd/2.0.0/s3cmd-2.0.0.tar.gz && \
    tar xvfz s3cmd-2.0.0.tar.gz && \
    cd s3cmd-2.0.0 && \
    python setup.py install

ADD ./.s3cfg /root/.s3cfg

# backup script

ADD ./mysqltos3.sh /usr/local/bin/mysqltos3
ADD ./mysqld.sh /usr/local/bin/mysqld.sh
ADD ./env_secrets_expand.sh /usr/local/bin/env_secrets_expand.sh

RUN rm /entrypoint.sh
ADD ./entrypoint.sh /entrypoint.sh

ADD ./supervisord/* /etc/supervisor/conf.d/

ENTRYPOINT ["/entrypoint.sh"]
CMD ["supervisord", "-n"]



