FROM registry.access.redhat.com/ubi9:9.3

MAINTAINER "Stuti Wali <Stuti.Wali@ibm.com>"

ARG PACKAGE_VERSION=v1.0.0
ARG NODE_VERSION=18.17.0

ENV SOURCE_DIR=$PWD
ENV PATH=/usr/local/bin:$PATH


RUN yum install -y yum-utils wget git gcc gcc-c++ make python3-devel \
    && wget https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-ppc64le.tar.gz \
    && tar -xzf node-v${NODE_VERSION}-linux-ppc64le.tar.gz

ENV PATH=$HOME_DIR/node-v${NODE_VERSION}-linux-ppc64le/bin:$PATH

RUN cd $SOURCE_DIR \
    && git clone https://github.com/jaredhanson/passport-local \
    && cd passport-local && git checkout $PACKAGE_VERSION \
    && npm install -g mocha \
    && npm install

CMD ["bash"]