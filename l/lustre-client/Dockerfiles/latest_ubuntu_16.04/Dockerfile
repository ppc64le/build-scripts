#Dockerfile for lustre-client (ubuntu/ppc64le:16.04)
FROM ppc64le/ubuntu:16.04

#Maintainer details
MAINTAINER Sandip Giri

#Install all required dependencies
RUN     apt-get update \
        && apt-get install -y git build-essential libtool m4 automake linux-headers-$(uname -r)

#Clone and build lustre-client
RUN git clone git://git.hpdd.intel.com/fs/lustre-release.git && \
cd lustre-release && \
sh autogen.sh && \
./configure --with-linux=/lib/modules/$(uname -r)/build/ && \
make && \
make install
