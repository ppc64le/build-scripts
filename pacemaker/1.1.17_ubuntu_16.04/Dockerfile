FROM ppc64le/ubuntu:latest
MAINTAINER Abhay Singh

ENV PACEMAKER_VERSION Pacemaker-1.1.17

RUN apt-get update && apt-get install -y apt-utils \
        build-essential \
        gcc \
        g++ \
        llvm \
        autoconf \
        clang \
        corosync-dev \
        libcorosync-common-dev \
        cppcheck \
        crmsh \
        libbz2-dev \
        libcfg-dev \
        libcpg-dev \
        libdbus-1-dev \
        libtool \
        libxml2-dev \
        libxslt1-dev \
        git \
        libglib2.0-dev \
        make \
        pkg-config \
        uuid-dev \
        libcmap-dev \
        libquorum-dev \
        libmcpp-dev \
	&& git clone https://github.com/ClusterLabs/pacemaker.git --branch ${PACEMAKER_VERSION} \
    	&& cd pacemaker && ./autogen.sh && ./configure && make && make install && make check \
    	&& apt-get update \
    	&& apt-get purge -y --auto-remove apt-utils \
        build-essential \
        gcc \
        g++ \
        llvm \
        autoconf \
        clang \
        cppcheck \
        crmsh \
        libbz2-dev \
        libcfg-dev \
        libcpg-dev \
        libdbus-1-dev \
        libtool \
        libxml2-dev \
        libxslt1-dev \
        git \
        libglib2.0-dev \
        make \
        pkg-config \
        uuid-dev \
        libcmap-dev \
        libquorum-dev \
        libmcpp-dev



CMD /etc/init.d/corosync start && /etc/init.d/pacemaker start && /bin/bash

