FROM registry.access.redhat.com/ubi9/ubi:9.3

MAINTAINER Abhishek Dwivedi <Abhishek.Dwivedi6@ibm.com>

ARG PACKAGE_VERSION=v2.10.14

RUN yum -y update && yum install -y nodejs npm python3 python3-devel ncurses git jq wget gcc-c++ && \
    wget https://go.dev/dl/go1.20.14.linux-ppc64le.tar.gz && \
    rm -rf /usr/local/go && \
    tar -C /usr/local -xzf go1.20.14.linux-ppc64le.tar.gz && \
    export PATH=$PATH:/usr/local/go/bin && \
    git clone https://github.com/nats-io/nats-server && \
    cd nats-server/ && \
    git checkout $PACKAGE_VERSION && \
    go build ./... 

CMD ["/bin/bash"]