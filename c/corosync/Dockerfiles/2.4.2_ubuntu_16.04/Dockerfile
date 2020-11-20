FROM ppc64le/ubuntu:xenial

MAINTAINER  BHUSHAN KALAMKAR

RUN apt-get update
RUN apt-get install -y  git make gcc automake autoconf libnss3-dev libtool zlib* check pkg-config crmsh  groff

RUN git clone git://github.com/asalkeld/libqb.git
RUN cd libqb && ./autogen.sh && ./configure \
                 && make \
                 &&  make install \
                 && make check

RUN git clone   https://github.com/corosync/corosync.git --branch=v2.4.2
RUN cd corosync  && ./autogen.sh && ./configure \
                && make \
                &&  make install \
                && make check


EXPOSE 5404

CMD service corosync start && /bin/bash
