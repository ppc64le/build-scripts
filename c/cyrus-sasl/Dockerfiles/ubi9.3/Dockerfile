FROM registry.access.redhat.com/ubi9/ubi:9.3

MAINTAINER Vipul Ajmera <Vipul.Ajmera@ibm.com>

ARG PACKAGE_VERSION=cyrus-sasl-2.1.28

RUN yum install -y gcc gcc-c++ make wget git cmake && \
    yum install -y autoconf automake openssl openssl-devel openssl-libs libtool && \
    git clone https://github.com/cyrusimap/cyrus-sasl && \
    cd cyrus-sasl/ && \
    git checkout $PACKAGE_VERSION && \
    ./autogen.sh && \
    ./configure --build ppc64le &&\
    make

CMD ["/bin/bash"]
