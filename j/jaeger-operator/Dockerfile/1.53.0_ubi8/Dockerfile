FROM registry.access.redhat.com/ubi8/ubi:8.7

MAINTAINER "Vinod K <Vinod.K1@ibm.com>"

ARG PACKAGE_VERSION=v1.53.0
ARG GO_VERSION=1.21.5

ENV GOPATH=/go
ENV PATH=/usr/local/bin/:$GOPATH/bin/:$PATH

RUN yum -y install wget sudo jq curl git make gcc time gnupg2 gcc-c++ python3 && \
    wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz && \
    tar -C /usr/local -xvzf go$GO_VERSION.linux-ppc64le.tar.gz && \
    rm -rf go$GO_VERSION.linux-ppc64le.tar.gz && \
    export PATH=/usr/local/go/bin:$PATH

RUN git clone https://github.com/jaegertracing/jaeger-operator && \
    cd jaeger-operator && \
    git checkout v1.53.0 && \
    export PATH=/usr/local/go/bin:$PATH && \
    go build ./...

CMD ["/bin/bash"]
