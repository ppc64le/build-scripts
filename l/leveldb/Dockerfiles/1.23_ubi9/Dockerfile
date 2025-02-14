FROM registry.access.redhat.com/ubi9/ubi:9.3

ARG PACKAGE_VERSION=1.23

RUN yum install -y git gcc-c++ gcc wget make  python3 yum-utils apr-devel perl openssl-devel automake autoconf libtool cmake

RUN git clone --recurse-submodules https://github.com/google/leveldb.git && \
    cd leveldb && \
    git checkout $PACKAGE_VERSION && \
    mkdir build && \
    cd build && \
    cmake .. && \
    cmake --build .

CMD ["/bin/bash"]

