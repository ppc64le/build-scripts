FROM registry.access.redhat.com/ubi8/ubi:8.5

ARG VAULT_VERSION=v1.9.1

ARG GO_VERSION=v1.17.13

ENV GOPATH=/go
ENV PATH=/usr/local/bin/:$GOPATH/bin/:$PATH

RUN yum install -y gcc-c++ wget tar gzip git make && \
    wget https://go.dev/dl/go${GO_VERSION}.linux-ppc64le.tar.gz && \
    tar xzf go${GO_VERSION}.linux-ppc64le.tar.gz && \
    mv go /usr/local/go && \
    ln -s /usr/local/go/bin/go /usr/local/bin/go && \
    rm -rf go${GO_VER}.linux-ppc64le.tar.gz && \
    mkdir -p /go/src/github.com/hashicorp && cd /go/src/github.com/hashicorp && \
    git clone https://github.com/hashicorp/vault && cd vault && \
    git checkout $VAULT_VERSION && \
    go mod tidy && \
    make bootstrap && \
    go mod vendor && \
    make && \
    yum remove -y gcc-c++ wget git make

FROM registry.access.redhat.com/ubi8/ubi-minimal

COPY --from=0 /go/src/github.com/hashicorp/vault/bin/vault /usr/bin/

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

USER 100

ENV SKIP_CHOWN true
ENV SKIP_SETCAP true

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["server", "-dev"]
