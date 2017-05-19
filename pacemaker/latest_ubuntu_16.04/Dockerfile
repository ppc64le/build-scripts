FROM ppc64le/ubuntu:16.04
MAINTAINER "Meghali Dhoble <dhoblem@us.ibm.com>"

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
        libmcpp-dev

RUN git clone https://github.com/ClusterLabs/pacemaker.git

RUN cd pacemaker && ./autogen.sh && ./configure && make && make install && make check

CMD /etc/init.d/corosync start && /etc/init.d/pacemaker start && /bin/bash
