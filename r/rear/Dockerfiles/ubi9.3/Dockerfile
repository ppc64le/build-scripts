FROM registry.access.redhat.com/ubi9/ubi:9.3
MAINTAINER Abhishek Dwivedi <Abhishek.Dwivedi6@ibm.com>

ARG PACKAGE_VERSION=rear-2.7

RUN yum update -y && \
    yum install git make -y && \
    git clone https://github.com/rear/rear.git && \
    cd rear/ && \
    git checkout $PACKAGE_VERSION && \
    make install

CMD ["/bin/bash"]

