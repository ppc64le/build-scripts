FROM registry.access.redhat.com/ubi9/ubi:9.3

MAINTAINER Abhishek Dwivedi <Abhishek.Dwivedi6@ibm.com>

ARG PACKAGE_VERSION=v3.12.3

RUN yum install -y git gcc-c++ zlib zlib-devel && \
    git clone https://github.com/python/cpython && \
    cd cpython/ && \
    git checkout $PACKAGE_VERSION && \
    ./configure && \
    make && \
    make install

CMD ["/bin/bash"]