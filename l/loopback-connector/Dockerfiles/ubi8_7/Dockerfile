FROM registry.access.redhat.com/ubi8:8.7

MAINTAINER "Stuti Wali <Stuti.Wali@ibm.com>"

ARG PACKAGE_VERSION=v6.1.0
ARG NODE_VERSION=12.19.1

ENV SOURCE_DIR=$PWD
ENV PATH=/usr/local/bin:$PATH

RUN yum install -y wget yum-utils git && \
    wget https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-ppc64le.tar.gz && \
    tar -xzf node-v${NODE_VERSION}-linux-ppc64le.tar.gz 

ENV PATH=$HOME_DIR/node-v${NODE_VERSION}-linux-ppc64le/bin:$PATH 


RUN cd $SOURCE_DIR && \
    git clone https://github.com/loopbackio/loopback-connector && \
    cd loopback-connector && \
    git checkout v6.1.0 && \
    npm install

CMD ["bash"]

