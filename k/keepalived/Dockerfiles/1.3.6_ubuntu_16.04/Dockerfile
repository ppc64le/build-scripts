FROM ppc64le/ubuntu:16.04

MAINTAINER "kiritim@us.ibm.com"

ENV KEEPALIVED_VERSION 1.3.6

RUN apt-get -y update && \
	apt-get install -y git \
		       wget \
                       build-essential \
                       openssl \
                       libssl-dev \
                       findutils \
                       autoconf \
                       libnfnetlink-dev \
                       autoconf-archive \
                       xserver-xorg-dev \
                       pkg-config \
                       libtool automake ipvsadm module-init-tools\
        && wget http://www.keepalived.org/software/keepalived-${KEEPALIVED_VERSION}.tar.gz \
        && tar -xvf keepalived-${KEEPALIVED_VERSION}.tar.gz \
        && cd keepalived-${KEEPALIVED_VERSION} \
        && ./configure && make all && make install \
        && apt-get remove --purge -y \
           git build-essential autoconf autoconf-archive automake wget libtool pkg-config \
        && apt-get autoremove -y \
        && rm -rf /var/lib/apt/lists/*

WORKDIR keepalived-${KEEPALIVED_VERSION}
RUN cp -R keepalived/etc/keepalived/ /etc/. && cp -R /usr/local/etc/sysconfig/ /etc/. && rm -rf /keepalived-1.3.6
ADD docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT sh /docker-entrypoint.sh && /bin/bash
