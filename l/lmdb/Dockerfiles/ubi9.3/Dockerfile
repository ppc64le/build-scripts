FROM registry.access.redhat.com/ubi9/ubi:9.3

MAINTAINER Abhishek Dwivedi <Abhishek.Dwivedi6@ibm.com>

ARG PACKAGE_VERSION=LMDB_0.9.31

RUN yum install -y git  gcc-c++  gcc wget make python yum-utils && \
    git clone https://github.com/LMDB/lmdb && \
    cd lmdb/libraries/liblmdb && \
    git checkout $PACKAGE_VERSION && \
    make && \
    make install

CMD ["/bin/bash"]