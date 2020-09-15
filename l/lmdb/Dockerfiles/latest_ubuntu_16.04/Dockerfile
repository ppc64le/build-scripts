FROM ppc64le/ubuntu:16.04
MAINTAINER "Yugandha Deshpande <yugandha@us.ibm.com>"

RUN apt-get update -y && \
    apt-get install -y build-essential g++ make git && \
    git clone https://github.com/LMDB/lmdb && \
    cd lmdb/libraries/liblmdb && \
    make && make install && \
    cd .. && rm -rf lmdb && \
    apt-get purge build-essential g++ make git -y && \
    apt-get autoremove -y

VOLUME ["/lmdb/data"]
CMD ["mdb_load"]

