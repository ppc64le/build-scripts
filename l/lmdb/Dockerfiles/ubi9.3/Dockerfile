FROM registry.access.redhat.com/ubi9/ubi:9.3

MAINTAINER Abhishek Dwivedi <Abhishek.Dwivedi6@ibm.com>

ARG PACKAGE_VERSION=LMDB_0.9.31

RUN yum install -y gcc gcc-c++ make wget git cmake && \
    git clone https://github.com/cyrusimap/cyrus-sasl && \
    cd cyrus-sasl/ && \
    git checkout $PACKAGE_VERSION && \
    ./autogen.sh && \
    ./configure --build ppc64le &&\
    make

CMD ["/bin/bash"]