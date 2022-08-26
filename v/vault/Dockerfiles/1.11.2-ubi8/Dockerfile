FROM registry.access.redhat.com/ubi8

MAINTAINER Vinod K <Vinod.K1@ibm.com>

ARG VAULT_VERSION=v1.11.2

RUN groupadd vault && \
    useradd -g vault vault
    
ENV GOPATH /go
ENV PATH $PATH:$GOPATH/bin   

RUN set -eux; \
    yum install -y openssl sudo \ 
    make git gcc wget && \
    wget https://golang.org/dl/go1.16.7.linux-ppc64le.tar.gz && \
    tar -C /usr/local -xvzf go1.16.7.linux-ppc64le.tar.gz && \
    rm -rf go1.16.7.linux-ppc64le.tar.gz && \    
    export PATH=/usr/local/go/bin:$PATH && \
    wget https://github.com/Yelp/dumb-init/releases/download/v1.2.2/dumb-init_1.2.2_ppc64le && \
    chmod a+x dumb-init_1.2.2_ppc64le && mv ./dumb-init_1.2.2_ppc64le ./dumb-init && cp ./dumb-init /usr/bin && \
    git clone https://github.com/ncopa/su-exec && cd su-exec && make && chmod a+x su-exec && cp ./su-exec /usr/bin && cd - && \
    mkdir -p /go/src/github.com/hashicorp && cd /go/src/github.com/hashicorp && \
    git clone https://github.com/hashicorp/vault && cd vault && \
    git checkout $VAULT_VERSION && \
    make bootstrap && make && \
    yum remove -y git make gcc wget && \
    rm -rf $GOPATH/src $GOPATH/pkg


RUN mkdir -p /vault/logs && \
    mkdir -p /vault/file && \
    mkdir -p /vault/config && \
    chown -R vault:vault /vault
    
# Expose the logs directory as a volume since there's potentially long-running
# state in there
VOLUME /vault/logs

# Expose the file directory as a volume since there's potentially long-running
# state in there
VOLUME /vault/file

# 8200/tcp is the primary interface that applications use to interact with
# Vault.
EXPOSE 8200

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["server", "-dev"]
