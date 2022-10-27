FROM registry.access.redhat.com/ubi8/ubi:8.4 as builder

ARG GRAFANA_VERSION=v9.1.6
 
ENV GOPATH=/grafana
ENV PATH=$PATH:/usr/local/go/bin

WORKDIR /usr/bin

#Install Go and Path
RUN yum -y update && \
yum -y install wget git gcc gcc-c++ && \
wget https://golang.org/dl/go1.17.1.linux-ppc64le.tar.gz && \
tar -C /usr/local -xzf go1.17.1.linux-ppc64le.tar.gz

RUN yum install -y python3 make && \
    git clone https://github.com/nodejs/node.git && \
    cd node && git checkout v18.9.0 && ./configure && make && make install

RUN npm install -g yarn

RUN cd / && mkdir grafana && cd grafana && \
    git clone https://github.com/grafana/grafana.git && cd grafana && \
    git checkout $GRAFANA_VERSION && \
    make gen-go && \
    go run build.go build && \
    yarn install --immutable && \
    go test -v ./pkg/... && \
    yum remove wget git make gcc gcc-c++ -y
 
FROM registry.access.redhat.com/ubi8/ubi-minimal:latest
 
COPY --from=builder /grafana/grafana/bin/linux-ppc64le/grafana-server /usr/bin
 
EXPOSE 3000

CMD ["grafana-server"]
