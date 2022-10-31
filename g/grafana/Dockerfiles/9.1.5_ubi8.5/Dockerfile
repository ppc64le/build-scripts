FROM registry.access.redhat.com/ubi8/ubi:8.4 as builder

ARG GRAFANA_VERSION=v9.1.6
ARG GO_VERSION=v1.17
ARG NODE_VERSION=v18.9.0
 
ENV GOPATH=/grafana
ENV PATH=$PATH:/usr/local/go/bin

WORKDIR /usr/bin

#Install Go and Path
RUN yum -y update && \
yum -y install wget git gcc gcc-c++ && \
wget https://golang.org/dl/go${GO_VERSION}.linux-ppc64le.tar.gz && \
tar -C /usr/local -xzf go${GO_VERSION}.linux-ppc64le.tar.gz

RUN yum install -y python3 make && \
    wget https://nodejs.org/dist/$NODE_VERSION/node-$NODE_VERSION-linux-ppc64le.tar.gz && \
    tar -C / -xzf node-$NODE_VERSION-linux-ppc64le.tar.gz && \
    rm -rf node-$NODE_VERSION-linux-ppc64le.tar.gz && \
    npm install -g yarn

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
