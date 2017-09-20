FROM ppc64le/ubuntu:16.04

MAINTAINER "Priya Seth <sethp@us.ibm.com>"

ENV ROCKSDB_VERSION 5.7.3

RUN apt-get update && apt-get install -y curl build-essential && \
        curl -L https://github.com/facebook/rocksdb/archive/v${ROCKSDB_VERSION}.tar.gz -o rocksdb.tar.gz && \
        tar xf rocksdb.tar.gz && \
        cd rocksdb-${ROCKSDB_VERSION} && \
        make install-shared && \
        cd / && rm -rf v${ROCKSDB_VERSION}.tar.gz && rm -rf rocksdb-${ROCKSDB_VERSION} && \
        apt-get purge -y curl build-essential && apt-get -y autoremove

CMD ["/bin/bash"]


