FROM registry.access.redhat.com/ubi9/ubi:9.3 

MAINTAINER "Vinod K <Vinod.K1@ibm.com>"

ARG PACKAGE_VERSION=master

RUN yum install -y git wget gcc gcc-c++ libtool autoconf make diffutils 

RUN git clone https://github.com/twitter/twemproxy && \
    cd twemproxy && \
    autoreconf -fvi && \
    ./configure --build=ppc64le-redhat-linux --enable-debug=full && \
    make && make install && \
    yum remove -y git wget gcc gcc-c++ libtool autoconf make diffutils

CMD ["/bin/bash"]
