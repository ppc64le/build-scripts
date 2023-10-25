FROM registry.access.redhat.com/ubi8:8.7

MAINTAINER "Stuti Wali <Stuti.Wali@ibm.com>"

ARG PACKAGE_VERSION=v1.9.4
ARG NODE_VERSION=12.19.1


ENV SOURCE_DIR=$PWD
ENV PATH=/usr/local/bin:$PATH


RUN yum update -y \
    && yum install -y git fontconfig-devel.ppc64le wget curl libXcomposite libXcursor procps-ng \
    && wget https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-ppc64le.tar.gz \
    && tar -xzf node-v${NODE_VERSION}-linux-ppc64le.tar.gz 

ENV PATH=$HOME_DIR/node-v${NODE_VERSION}-linux-ppc64le/bin:$PATH 

RUN cd $SOURCE_DIR \
    && git clone https://github.com/Leaflet/Leaflet \
    && cd Leaflet && git checkout $PACKAGE_VERSION 

RUN npm install 

WORKDIR /Leaflet
CMD ["bash"]
