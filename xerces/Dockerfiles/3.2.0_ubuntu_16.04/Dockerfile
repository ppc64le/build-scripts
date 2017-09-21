FROM ppc64le/ubuntu:16.04

MAINTAINER Snehlata Mohite <smohite@us.ibm.com>

ENV XERCES_VERSION Xerces-C_3_2_0

RUN apt-get update \
    && apt-get install -y git build-essential automake autoconf libtool* make \
    && git clone https://github.com/apache/xerces-c.git --branch ${XERCES_VERSION} \
    && cd xerces-c && ./reconf && ./configure && make && make install && make check \
    && rm -rf /xerces-c\
    && apt-get purge -y --auto-remove git build-essential automake autoconf libtool* make

