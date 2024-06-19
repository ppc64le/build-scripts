FROM registry.access.redhat.com/ubi9/ubi:9.3
MAINTAINER Abhishek Dwivedi <Abhishek.Dwivedi6@ibm.com>

ARG PACKAGE_VERSION=3.0.2
ARG PACKAGE_NAME=python-semver
ARG PACKAGE_URL=https://github.com/python-semver/python-semver

RUN yum update -y && \
    yum install git gcc gcc-c++ make python3 python3-devel -y && \
    git clone $PACKAGE_URL && \
    cd $PACKAGE_NAME && \
    git checkout $PACKAGE_VERSION && \
    python3 -m pip install --upgrade pip && \
    python3 -m pip install .
    
CMD ["/bin/bash"]