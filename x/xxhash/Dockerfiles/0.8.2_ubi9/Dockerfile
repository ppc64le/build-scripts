FROM registry.access.redhat.com/ubi9/ubi:9.3

MAINTAINER "Vinod K <Vinod.K1@ibm.com>"

ARG PACKAGE_VERSION=v0.8.2

RUN yum install -y git gcc-c++ gcc wget make

RUN git clone https://github.com/Cyan4973/xxHash && \
    cd xxHash && \
    git checkout $PACKAGE_VERSION && \
    make && make install

CMD ["/usr/local/bin/xxhsum"]
