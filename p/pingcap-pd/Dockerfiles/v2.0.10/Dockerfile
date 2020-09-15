FROM ppc64le/golang:1.8.1
MAINTAINER "Sandip Giri <sgiri@us.ibm.com>"

RUN mkdir -p /go/src/github.com/pingcap/ && cd /go/src/github.com/pingcap/ && \
    git clone https://github.com/pingcap/pd.git && \
    cd pd && git checkout v2.0.10 && make && \
    cp -f ./bin/pd-server /go/bin/pd-server  

EXPOSE 2379 2380

ENTRYPOINT ["pd-server"]
