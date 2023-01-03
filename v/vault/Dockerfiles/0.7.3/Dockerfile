FROM ppc64le/alpine:3.6
MAINTAINER Vaibhav Sood <vaibhavs@us.ibm.com>

# This is the release of Vault to pull in.
ARG VAULT_VERSION=v0.7.3

# Create a vault user and group first so the IDs get set the same way,
# even as the rest of this may change over time.
RUN addgroup vault && \
    adduser -S -G vault vault

ENV GOPATH /go
ENV PATH $PATH:$GOPATH/bin

# Set up our base tools, and Vault.
RUN apk update && apk add --no-cache git make bash libcap musl-dev gcc wget go && \
    mkdir -p /tmp/build && \
    cd /tmp/build && \
    git clone https://github.com/Yelp/dumb-init && cd dumb-init && make && cp dumb-init /bin && \
    wget https://github.com/tianon/gosu/releases/download/1.10/gosu-ppc64el && cp gosu-ppc64el /bin/gosu && chmod +x /bin/gosu && \
    cd /tmp && \
    rm -rf /tmp/build && \
    rm -rf /root/.gnupg && \
    mkdir -p /go/src/github.com/hashicorp && cd /go/src/github.com/hashicorp && \
    git clone https://github.com/hashicorp/vault && cd vault && \
    git checkout $VAULT_VERSION && \
    make bootstrap && make && \
    apk del git make gcc wget bash musl-dev go 

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
ENTRYPOINT ["docker-entrypoint.sh"]

# By default you'll get a single-node development server that stores everything
# in RAM and bootstraps itself. Don't use this configuration for production.
CMD ["server", "-dev"]

