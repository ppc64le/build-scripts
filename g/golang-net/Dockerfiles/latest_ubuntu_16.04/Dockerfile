FROM golang:latest
MAINTAINER "Atul Sowani <sowania@us.ibm.com>"

ENV GOROOT=/usr/local/go
ENV PATH=$GOROOT/bin:$PATH
ENV GOPATH=/tmp/workspace
ENV PATH=$PATH:$GOPATH/bin

RUN apt-get -y update && \
    apt-get install -y git wget ssh curl gcc && \

    mkdir -p /tmp/workspace/bin /tmp/workspace/src/golang.org/x \
             /tmp/workspace/pkg && \
    cd /tmp/workspace/src/golang.org/x && \
    git clone https://github.com/golang/text.git && \
    git clone https://github.com/golang/crypto.git && \
    git clone https://github.com/golang/net.git && \

    go get golang.org/x/sys/unix && \
    go get golang.org/x/tools/go/buildutil && \
    go get golang.org/x/tools/go/loader && \

    mv /tmp/workspace/src/golang.org/x/net/icmp/diag_test.go /tmp/workspace/src/golang.org/x/net/icmp/diag_test.go.org && \
    cd /tmp/workspace/src/golang.org/x/net && \
    go test -v ./... && \
    apt-get remove --purge -y git wget ssh curl gcc && \
    apt-get auto-remove -y

CMD ["/bin/bash"]
