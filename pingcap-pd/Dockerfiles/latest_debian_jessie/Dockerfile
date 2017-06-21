FROM ppc64le/golang:1.8

MAINTAINER sethp@us.ibm.com

ENV GOPATH /pd
ENV PATH $GOPATH/bin:$PATH

RUN cd / && git clone https://github.com/pingcap/pd.git && cd /pd && go get github.com/pingcap/pd; exit 0

RUN cd $GOPATH/src/github.com/pingcap/pd && make && \
        rm -rf vendor && ln -s _vendor/vendor vendor && \
        make check && go test $(go list ./...| grep -vE 'vendor|pd-server') && \
        cp -f ./bin/pd-server /go/bin/pd-server

EXPOSE 2379 2380

ENTRYPOINT ["pd-server"]

