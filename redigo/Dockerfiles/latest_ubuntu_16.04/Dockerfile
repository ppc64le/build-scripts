FROM ppc64le/ubuntu:16.04
MAINTAINER "Lysanne Fernandes <lysannef@us.ibm.com>"

ENV GOPATH=$HOME/gopath GOROOT=/usr/lib/go-1.6 PATH=$PATH:/usr/bin:$GOPATH/bin

RUN apt-get update -y && apt-get install -y golang-go git && \
    cd $HOME && go get -u github.com/FiloSottile/gvt && \
    cd $GOPATH/src/github.com/FiloSottile/gvt && cd $GOPATH/bin && \
    ./gvt fetch github.com/garyburd/redigo && \
    cd $GOPATH/src/github.com/FiloSottile/gvt/vendor && \
    go build ./... && \
    apt-get purge -y git && apt-get autoremove -y

CMD ["/bin/bash"]
