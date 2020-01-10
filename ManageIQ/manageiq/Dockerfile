# This Dockerfile has been adapted from the Dockerfile
# maintained by the ManageIQ community at
# https://github.com/ManageIQ/manageiq
# to work on Power on UBI base

ARG IMAGE_REF=ubi7-latest
FROM manageiq/manageiq-ui-worker:${IMAGE_REF}
MAINTAINER "Priya Seth <sethp@us.ibm.com>"

ENV DATABASE_URL=postgresql://root@localhost/vmdb_production?encoding=utf8&pool=5&wait_timeout=5

RUN yum -y install --setopt=tsflags=nodocs \
                   mod_ssl                 \
                   openssh-clients         \
                   openssh-server          \
                   &&                      \
    yum clean all

VOLUME [ "/var/lib/pgsql/data" ]
VOLUME [ ${APP_ROOT} ]

RUN wget https://github.com/libevent/libevent/releases/download/release-2.1.11-stable/libevent-2.1.11-stable.tar.gz && \
	tar -zxvf libevent-2.1.11-stable.tar.gz && cd libevent-2.1.11-stable && sh autogen.sh && \
   	./configure && make && make install

ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib

RUN wget https://github.com/memcached/memcached/archive/1.5.20.tar.gz && \
	tar -zxvf 1.5.20.tar.gz && cd memcached-1.5.20 && sh autogen.sh && ./configure --prefix=/usr && \
	make && make install && useradd memcached

# Initialize SSH
RUN ssh-keygen -q -t dsa -N '' -f /etc/ssh/ssh_host_dsa_key && \
    ssh-keygen -q -t rsa -N '' -f /etc/ssh/ssh_host_rsa_key && \
    ssh-keygen -q -t rsa -N '' -f /root/.ssh/id_rsa && \
    cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys && \
    for key in /etc/ssh/ssh_host_*_key.pub; do echo "localhost $(cat ${key})" >> /root/.ssh/known_hosts; done && \
    echo "root:smartvm" | chpasswd && \
    chmod 700 /root/.ssh && \
    chmod 600 /root/.ssh/*

## Copy/link the appliance files again so that we get ssl
RUN ${APPLIANCE_ROOT}/setup && \
    mv /etc/httpd/conf.d/ssl.conf{,.orig} && \
    echo "# This file intentionally left blank. ManageIQ maintains its own SSL configuration" > /etc/httpd/conf.d/ssl.conf

## Overwrite entrypoint from pods repo
COPY docker-assets/entrypoint /usr/local/bin

EXPOSE 443 22

LABEL name="manageiq"
