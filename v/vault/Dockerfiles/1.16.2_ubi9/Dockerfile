FROM registry.access.redhat.com/ubi9 as builder

ARG VAULT_VERSION=v1.17.2

ARG GO_VERSION=1.22.5

RUN yum install -y gcc-c++ wget tar gzip git make && \
    wget https://go.dev/dl/go${GO_VERSION}.linux-ppc64le.tar.gz && \
    tar -C /usr/local -xf go${GO_VERSION}.linux-ppc64le.tar.gz && \
    export GOROOT=/usr/local/go && \
    export GOPATH=$HOME && \
    export PATH=$GOPATH/bin:$GOROOT/bin:$PATH && \
    git clone https://github.com/hashicorp/vault && cd vault && \
    git checkout $VAULT_VERSION && \
    git clone https://github.com/dmarkham/enumer && \
    cd enumer && \
    git checkout v1.5.9 && \
    go build ./... && \
    mv enumer /usr/local/bin && cd .. && \
    make

FROM registry.access.redhat.com/ubi9/ubi-minimal

COPY --from=builder /vault/bin/vault /usr/bin/

RUN microdnf install -y ca-certificates openssl libcap tzdata procps shadow-utils util-linux

RUN groupadd --gid 1000 vault && \
    adduser --uid 100 --system -g vault vault && \
    usermod -a -G root vault

ENV HOME /home/vault

RUN mkdir -p /vault/logs && \
    mkdir -p /vault/file && \
    mkdir -p /vault/config && \
    mkdir -p $HOME && \
    chown -R vault /vault && chown -R vault $HOME && \
    chgrp -R 0 $HOME && chmod -R g+rwX $HOME && \
    chgrp -R 0 /vault && chmod -R g+rwX /vault

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

USER 100
ENV SKIP_CHOWN true
ENV SKIP_SETCAP true

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["server", "-dev"]
