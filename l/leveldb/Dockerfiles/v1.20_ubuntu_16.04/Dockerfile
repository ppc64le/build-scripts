FROM ppc64le/ubuntu:16.04
MAINTAINER "Yugandha Deshpande <yugandha@us.ibm.com>"

ENV LEVELDB_VERSION v1.20

RUN  apt-get update && \
     apt-get install git \
     build-essential \
     g++ \
     make \
     git-core \
     libsnappy-dev -y && \
 git clone https://github.com/google/leveldb --branch=${LEVELDB_VERSION} && \
 cd leveldb && \
 make && \
 mv out-static/lib* out-shared/lib* /usr/local/lib/ && \
 cd include && cp -R leveldb /usr/local/include/ && \
 ldconfig && \
 cd .. && \
 mv out-static out-shared ../ && rm -rf * && mv ../out-static ../out-shared . && \
 apt-get purge -y git build-essential g++ make git-core && \
 apt-get autoremove -y 
CMD ["/bin/bash"]
