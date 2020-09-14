FROM ppc64le/ubuntu:16.04
MAINTAINER "Yugandha Deshpande <yugandha@us.ibm.com>"

ENV LMDB_VERSION LMDB_0.9.21

RUN apt-get update -y && \
    apt-get install -y build-essential g++ make git && \
    git clone https://github.com/LMDB/lmdb --branch=${LMDB_VERSION} && \
    cd lmdb/libraries/liblmdb && \
    make && make install && \
    cd .. && rm -rf lmdb && \
    apt-get purge build-essential g++ make git -y && \
    apt-get autoremove -y

VOLUME ["/lmdb/data"]
CMD ["mdb_load"]

