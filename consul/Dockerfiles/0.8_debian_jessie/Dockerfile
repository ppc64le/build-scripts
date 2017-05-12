FROM ppc64le/debian:jessie
MAINTAINER Vaibhav Sood

ENV CONSUL_VERSION=0.8.1
ENV GOPATH /go
ENV PATH $PATH:/usr/local/go/bin:$GOPATH/bin
ENV DOCKER_BASE_VERSION=0.0.4

ENV HASHICORP_RELEASES=https://releases.hashicorp.com

RUN addgroup consul && \
    adduser --ingroup consul consul && \
    apt-get update && apt-get install -y ca-certificates curl gnupg libcap-dev openssl git make gcc wget && \
    mkdir -p /tmp/build && \
    cd /tmp/build && \
     git clone https://github.com/Yelp/dumb-init && cd dumb-init && make && cp dumb-init /bin && \
     wget https://github.com/tianon/gosu/releases/download/1.10/gosu-ppc64el && cp gosu-ppc64el /bin/gosu && chmod +x /bin/gosu && \
     wget https://storage.googleapis.com/golang/go1.8.1.linux-ppc64le.tar.gz && tar -C /usr/local -xzf go1.8.1.linux-ppc64le.tar.gz && \
    mkdir -p /go/src/github.com/hashicorp && cd /go/src/github.com/hashicorp && \
    git clone https://github.com/hashicorp/consul.git && \
    cd consul && \
    go get github.com/mitchellh/gox && \
    gox -os=linux -arch=ppc64le -output=ppc64le/consul && cp ppc64le/consul /bin && chmod +x /bin/consul && \
    mkdir -p /consul/data && \
    mkdir -p /consul/config && \
    chown -R consul:consul /consul && \
    apt-get purge git wget make gcc curl --force-yes -y && apt-get autoremove -y && \
    rm -rf /tmp/build && rm -rf /root/.gnupg 

VOLUME /consul/data

# request forwarding.
EXPOSE 8300
EXPOSE 8301 8301/udp 8302 8302/udp
EXPOSE 8400 8500 8600 8600/udp
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["agent", "-dev", "-client", "0.0.0.0"]
