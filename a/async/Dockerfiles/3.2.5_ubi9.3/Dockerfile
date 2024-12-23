FROM registry.access.redhat.com/ubi9:9.3

MAINTAINER "Ramnath Nayak <Ramnath.Nayak@ibm.com>"

ARG PACKAGE_VERSION=v3.2.5
ARG NODE_VERSION=18.1.0

ENV SOURCE_DIR=$PWD
ENV PATH=/usr/local/bin:$PATH

#install node
RUN yum install -y git wget make \
    && wget https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-ppc64le.tar.gz \
    && tar -xzf node-v${NODE_VERSION}-linux-ppc64le.tar.gz 

ENV PATH=$HOME_DIR/node-v${NODE_VERSION}-linux-ppc64le/bin:$PATH 

RUN cd $SOURCE_DIR \
    && git clone https://github.com/caolan/async.git \
    && cd async && git checkout $PACKAGE_VERSION \
    && npm install 

CMD ["bash"]
