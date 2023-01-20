FROM registry.access.redhat.com/ubi8

MAINTAINER Mahima Gaikwad <mahima.gaikwad@ibm.com>

ARG VAULT_VERSION=v1.7.0
ARG GO_VERSION=1.16.7

# Create a vault user and group first so the IDs get set the same way,
# even as the rest of this may change over time.
RUN groupadd vault && \
    useradd -g vault vault

ENV GOPATH /go
ENV PATH $PATH:$GOPATH/bin

# Set up our base tools, and Vault.
RUN set -eux; \
    yum install -y openssl sudo \ 
    make git gcc wget && \
    wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz && \
    tar -C /usr/local -xvzf go$GO_VERSION.linux-ppc64le.tar.gz && \
    rm -rf go$GO_VERSION.linux-ppc64le.tar.gz && \    
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

# /vault/logs is made available to use as a location to store audit logs, if
# desired; /vault/file is made available to use as a location with the file
# storage backend, if desired; the server will be started with /vault/config as
# the configuration directory so you can add additional config files in that
# location.
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

# The entry point script uses dumb-init as the top-level process to reap any
# zombie processes created by Vault sub-processes.
#
# For production derivatives of this container, you shoud add the IPC_LOCK
# capability so that Vault can mlock memory.
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]

# By default you'll get a single-node development server that stores everything
# in RAM and bootstraps itself. Don't use this configuration for production.
CMD ["server", "-dev"]
