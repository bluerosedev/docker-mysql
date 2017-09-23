FROM mysql

RUN apt-get update

# Install supervisor

RUN apt-get install -y supervisor less vim

# install cron

RUN apt-get install -y cron

# install s3cmd

RUN apt-get install -y python-setuptools wget
RUN wget http://downloads.sourceforge.net/project/s3tools/s3cmd/2.0.0/s3cmd-2.0.0.tar.gz
RUN tar xvfz s3cmd-2.0.0.tar.gz
RUN cd s3cmd-2.0.0 && python setup.py install
RUN rm s3cmd-2.0.0.tar.gz

ADD ./s3cfg /root/.s3cfg

# backup script

ADD ./mysqltos3.sh /usr/local/bin/mysqltos3
ADD ./mysqld.sh /usr/local/bin/mysqld.sh

RUN rm /entrypoint.sh
ADD ./entrypoint.sh /entrypoint.sh

# Supervisord configuration file

ADD ./supervisord/* /etc/supervisor/conf.d/

ENTRYPOINT ["/entrypoint.sh"]


