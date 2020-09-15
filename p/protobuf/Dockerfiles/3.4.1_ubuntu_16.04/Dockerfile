FROM ppc64le/ubuntu:16.04

MAINTAINER "Priya Seth <sethp@us.ibm.com>

ENV PROTOBUF_VERSION 3.4.1
ENV PROTOBUF_REPOSITORY https://github.com/google/protobuf
ENV PROTOBUF_DIR protobuf

# Install dependent packages
RUN  apt-get update \
     && apt-get install -y git autoconf libtool automake g++ make curl unzip\
     && git clone ${PROTOBUF_REPOSITORY} -b v${PROTOBUF_VERSION} --depth 1 ./${PROTOBUF_DIR}\
     && cd ./${PROTOBUF_DIR} \
     && ./autogen.sh \
     && ./configure --prefix=/usr \
     &&  make && make check && make install\
     && cd .. && rm -rf protobuf\
     && rm -rf ./${PROTOBUF_DIR}\
     && apt-get autoremove -y make curl unzip automake git libtool g++ autoconf\
     && apt-get clean

ENV LD_LIBRARY_PATH /usr/local/lib

ADD . /proto
WORKDIR /proto
# Entry point
ENTRYPOINT ["protoc"]

