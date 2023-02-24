FROM registry.access.redhat.com/ubi8/ubi:8.4 as builder

ARG GRAFANA_VERSION=v9.1.6
ARG GO_VERSION=1.17

ENV GOPATH=/grafana
ENV PATH=$PATH:/usr/local/go/bin

WORKDIR /usr/bin

#Install Go and Path
RUN yum -y update && \
yum -y install wget git gcc gcc-c++ && \
wget https://golang.org/dl/go${GO_VERSION}.linux-ppc64le.tar.gz && \
tar -C /usr/local -xzf go${GO_VERSION}.linux-ppc64le.tar.gz

RUN yum install -y python3 make && \
        curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash && \
        export NVM_DIR="$HOME/.nvm" && \
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm && \
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion && \
        nvm install 18.9.0 && \
        nvm use 18.9.0 && \
        npm install -g yarn

RUN cd / && mkdir grafana && cd grafana && \
    git clone https://github.com/grafana/grafana.git && cd grafana && \
    git checkout $GRAFANA_VERSION && \
    make gen-go && \
    go run build.go build && \
    yum remove wget git make gcc gcc-c++ -y

FROM registry.access.redhat.com/ubi8/ubi-minimal:latest

COPY --from=builder /grafana/grafana/bin/linux-ppc64le/grafana-server /usr/bin

EXPOSE 3000

CMD ["grafana-server"]
