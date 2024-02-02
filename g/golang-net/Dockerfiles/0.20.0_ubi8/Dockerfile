FROM registry.access.redhat.com/ubi8/ubi:8.7

MAINTAINER "Vinod K <Vinod.K1@ibm.com>"

ARG PACKAGE_VERSION=v0.20.0
ARG GO_VERSION=1.21.5

ENV GOPATH=/go
ENV PATH=/usr/local/bin/:$GOPATH/bin/:$PATH

RUN yum -y install git wget gcc gcc-c++ && \
    wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz && \
    tar -C /usr/local -xvzf go$GO_VERSION.linux-ppc64le.tar.gz && \
    rm -rf go$GO_VERSION.linux-ppc64le.tar.gz && \
    export PATH=/usr/local/go/bin:$PATH

RUN git clone https://github.com/golang/net && \
    cd net && \
    git checkout $PACKAGE_VERSION && \
    export PATH=/usr/local/go/bin:$PATH && \
    go build ./...

CMD ["/bin/bash"]
