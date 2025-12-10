FROM registry.access.redhat.com/ubi9:9.6 as builder

# This is the release of Consul to pull in.
ARG CONSUL_VERSION=v1.22.0

RUN set -eux && \
    yum install -y curl libcap iputils glibc --allowerasing

ENV GOPATH=/go
ENV PATH=$PATH:$GOPATH/bin

RUN set -eux; \
    yum install -y git gcc make wget && \
    wget https://golang.org/dl/go1.25.3.linux-ppc64le.tar.gz && \
    tar -C /usr/local -xvzf go1.25.3.linux-ppc64le.tar.gz && \
    rm -rf go1.25.3.linux-ppc64le.tar.gz && \
    export PATH=/usr/local/go/bin:$PATH && \
    go install gotest.tools/gotestsum@latest && \
    go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest && \
    wget https://github.com/Yelp/dumb-init/releases/download/v1.2.2/dumb-init_1.2.2_ppc64le && \
    chmod a+x dumb-init_1.2.2_ppc64le && mv dumb-init_1.2.2_ppc64le dumb-init && \
    cp dumb-init /usr/bin && \
    git clone https://github.com/ncopa/su-exec && cd su-exec && make && chmod a+x su-exec && cp su-exec /usr/bin && cd - && \
    mkdir -p /go/src/github.com/hashicorp && cd /go/src/github.com/hashicorp && \
    git clone https://github.com/hashicorp/consul && cd consul && \
    git checkout $CONSUL_VERSION && \
    make dev && \
    cp /go/src/github.com/hashicorp/consul/bin/consul /bin/consul && \
    chmod +x /bin/consul && \
    yum remove -y git make gcc wget && \
    rm -rf $GOPATH/src $GOPATH/pkg && \
    rm -rf /usr/local/go

# Debug spot-check
RUN find / -name "consul"

##
FROM registry.access.redhat.com/ubi9:9.6

# Copy compiled binaries from builder
COPY --from=builder /bin/consul /usr/local/bin/consul
COPY --from=builder /usr/bin/dumb-init /usr/bin/dumb-init
COPY --from=builder /usr/bin/su-exec /usr/bin/su-exec

# Verify consul runs
RUN export PATH=$PATH:/usr/local/bin && consul version

# Setup consul user
RUN groupadd consul && adduser -g consul consul

# Consul directories
RUN mkdir -p /consul/data && \
    mkdir -p /consul/config && \
    chown -R consul:consul /consul

# set up nsswitch.conf for Go's "netgo" implementation which is used by Consul,
# otherwise DNS supercedes the container's hosts file, which we don't want.
RUN test -e /etc/nsswitch.conf || echo 'hosts: files dns' > /etc/nsswitch.conf

# Expose the consul data directory as a volume since there's mutable state in there.
VOLUME /consul/data

# Server RPC is used for communication between Consul clients and servers for internal
# request forwarding.
EXPOSE 8300

# Serf LAN and WAN (WAN is used only by Consul servers) are used for gossip between
# Consul agents. LAN is within the datacenter and WAN is between just the Consul
# servers in all datacenters.
EXPOSE 8301 8301/udp 8302 8302/udp

# HTTP and DNS (both TCP and UDP) are the primary interfaces that applications
# use to interact with Consul.
EXPOSE 8500 8600 8600/udp

# Consul doesn't need root privileges so we run it as the consul user from the
# entry point script. The entry point script also uses dumb-init as the top-level
# process to reap any zombie processes created by Consul sub-processes.
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]

# By default you'll get an insecure single-node development server that stores
# everything in RAM, exposes a web UI and HTTP endpoints, and bootstraps itself.
# Don't use this configuration for production.
CMD ["agent", "-dev", "-client", "0.0.0.0"]
