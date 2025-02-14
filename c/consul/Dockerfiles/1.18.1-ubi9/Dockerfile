FROM registry.access.redhat.com/ubi9:9.3

ARG PACKAGE_VERSION=v1.18.1
ARG GO_VERSION=go1.22.1

RUN yum install -y wget tar zip gcc-c++ make git procps diffutils && \
    wget  https://go.dev/dl/$GO_VERSION.linux-ppc64le.tar.gz && \
    tar -C /usr/local -xzf $GO_VERSION.linux-ppc64le.tar.gz && \
    ln -sf /usr/local/go/bin/go /usr/bin/ && \
    ln -sf /usr/local/go/bin/godoc /usr/bin/  && \
    rm -rf $GO_VERSION.linux-ppc64le.tar.gz

RUN go install gotest.tools/gotestsum@latest && \
    go install github.com/golangci/golangci-lint/cmd/golangci-lint@v1.45.2 && \
    ulimit -n 2048 && \
    umask 0022

ENV PATH=$GOPATH/bin:$PATH

RUN git clone https://github.com/hashicorp/consul && \
    cd consul && \
    git checkout $PACKAGE_VERSION && \
    go mod download && \
    go mod tidy && \
    make dev

CMD ["bash"]
