FROM ppc64le/golang:1.9

MAINTAINER "Lysanne Fernandes <lysannef@us.ibm.com>"

ENV GOPATH=/usr/lib/go

RUN apt-get update -y && apt-get install -y git && \
    mkdir -p /usr/lib/go/src/github.com/twinj && \
    cd /usr/lib/go/src/github.com/twinj && \
    git clone https://github.com/twinj/uuid.git && \
    go get github.com/stretchr/testify && \
    apt-get purge -y git && apt-get autoremove -y

CMD ["/bin/bash"]
