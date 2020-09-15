FROM ubuntu:18.04

MAINTAINER "Priya Seth <sethp@us.ibm.com>"

RUN apt-get update -y && \
        apt-get install -y git libtool  pkg-config autoconf automake build-essential gettext && \
        git clone https://github.com/jedisct1/libsodium.git && \
        cd libsodium && ./autogen.sh && ./configure && make && \
        make check && make install

CMD ["/bin/bash"]
