FROM ppc64le/ubuntu:16.04
MAINTAINER "Yugandha Deshpande <yugandha@us.ibm.com>"

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-ppc64el
ENV PATH /usr/lib/jvm/java-8-openjdk-ppc64el/bin:$PATH
ENV VERSION 1.4.1

RUN apt-get update \
    && apt-get install git wget tar autoconf libtool \
        build-essential python-dev python-six python-virtualenv \
        libcurl4-nss-dev libsasl2-dev libsasl2-modules maven \
        libapr1-dev libsvn-dev zlib1g-dev openjdk-8-jdk -y \
#Clone and build source
    && export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-ppc64el \
    && git clone https://github.com/apache/mesos \
    && cd mesos/ && git checkout $VERSION \
    && ./bootstrap \
    && mkdir build \
    && cd build \
    && mkdir /usr/local/mesos \
    && ../configure --prefix=/usr/local/mesos \
#(create this folder so as to have all the required files at common place)
    && make && make install \
    && cd ../.. && rm -rf mesos \
#Remove dependencies
    && apt-get purge --auto-remove git wget autoconf libtool \
        build-essential python-dev python-six python-virtualenv \
        libcurl4-nss-dev libsasl2-dev libsasl2-modules maven \
        libapr1-dev libsvn-dev zlib1g-dev openjdk-8-jdk -y \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN apt-get update \
    && apt-get install docker.io libsvn-dev libcurl3-nss -y
EXPOSE 2375

