FROM registry.access.redhat.com/ubi9/ubi:9.3

MAINTAINER Abhishek Dwivedi <Abhishek.Dwivedi6@ibm.com>

ARG PACKAGE_VERSION=3.7.0

RUN yum install -y git make gcc gcc-c++ openssl openssl-devel pcre2 pcre2-devel systemd-devel zlib-devel && \
    yum install -y curl autoconf automake libtool pkg-config --skip-broken && \
    git clone https://github.com/ossec/ossec-hids && \
    cd ossec-hids/ && \
    git checkout $PACKAGE_VERSION && \
    (cd src/ && make TARGET=server build) && \
    (cd src/ && make TARGET=server install)

CMD ["/bin/bash"]