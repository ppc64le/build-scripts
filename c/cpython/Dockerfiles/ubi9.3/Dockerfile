FROM registry.access.redhat.com/ubi9/ubi:9.3

MAINTAINER Vipul Ajmera <Vipul.Ajmera@ibm.com>

ARG PACKAGE_VERSION=v3.12.3

RUN yum install -y git gcc-c++ zlib-devel libtool && \
    git clone https://github.com/python/cpython && \
    cd cpython/ && \
    git checkout $PACKAGE_VERSION && \
    ./configure && \
    make 

CMD ["/bin/bash"]
