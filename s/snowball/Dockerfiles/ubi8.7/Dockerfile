FROM registry.access.redhat.com/ubi8/ubi:8.7

MAINTAINER "Abhishek Dwivedi <Abhishek.Dwivedi6@ibm.com>"

ARG PACKAGE_VERSION=v2.2.0

RUN yum install -y git gcc make python38 &&\
        git clone https://github.com/snowballstem/snowball.git && \
        cd snowball && \
        git checkout $PACKAGE_VERSION && \
        make

CMD ["/bin/bash"]