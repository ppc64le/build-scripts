FROM registry.access.redhat.com/ubi9/ubi:9.3
 
MAINTAINER "Vinod K <Vinod.K1@ibm.com>"
 
ARG PACKAGE_VERSION=1.0.19
 
RUN yum install -y git gcc gcc-c++ make cmake libtool autoconf
	
RUN git clone https://github.com/jedisct1/libsodium && \
    cd libsodium && \
    git checkout $PACKAGE_VERSION && \
    autoreconf -fvi && \
    ./configure --build=ppc64le-redhat-linux && \
    make && \ 
    make install
 
CMD ["/bin/bash"]
