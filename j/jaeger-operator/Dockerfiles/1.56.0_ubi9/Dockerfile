FROM registry.access.redhat.com/ubi9/ubi:9.3

MAINTAINER "Vinod K <Vinod.K1@ibm.com>"

ARG PACKAGE_VERSION=v1.56.0
ARG GO_VERSION=1.21.6

ENV GOPATH=/go
ENV PATH=/usr/local/bin/:$GOPATH/bin/:$PATH

RUN yum -y install wget sudo jq libcurl-devel git make gcc time gnupg2 gcc-c++ python3 && \
        wget https://go.dev/dl/go${GO_VERSION}.linux-ppc64le.tar.gz && \
        tar -C  /usr/local -xf go${GO_VERSION}.linux-ppc64le.tar.gz && \
        export GOROOT=/usr/local/go && \
        export GOPATH=$HOME && \
        export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

RUN git clone https://github.com/jaegertracing/jaeger-operator && \
    cd jaeger-operator && \
    git checkout $PACKAGE_VERSION && \
    export PATH=/usr/local/go/bin:$PATH && \
    go build ./...

CMD ["/bin/bash"]

