FROM registry.access.redhat.com/ubi8

# This is the release of Consul to pull in.
ARG CONSUL_VERSION=v1.9.4

# Create a consul user and group first so the IDs get set the same way, even as
# the rest of this may change over time.
RUN groupadd consul && \
    adduser  -g  consul consul

# Set up certificates, base tools, and Consul.
RUN set -eux && \
    yum install -y curl libcap iputils glibc 

ENV GOPATH /go
ENV PATH $PATH:$GOPATH/bin

RUN set -eux; \
    yum install -y git gcc make wget && \
    wget https://golang.org/dl/go1.16.7.linux-ppc64le.tar.gz && \
    tar -C /usr/local -xvzf go1.16.7.linux-ppc64le.tar.gz && \
    rm -rf go1.16.7.linux-ppc64le.tar.gz && \
    export PATH=/usr/local/go/bin:$PATH && \
    wget https://github.com/Yelp/dumb-init/releases/download/v1.2.2/dumb-init_1.2.2_ppc64le && \
    chmod a+x dumb-init_1.2.2_ppc64le && mv ./dumb-init_1.2.2_ppc64le ./dumb-init && cp ./dumb-init /usr/bin && \
    git clone https://github.com/ncopa/su-exec && cd su-exec && make && chmod a+x su-exec && cp ./su-exec /usr/bin && cd - && \
    mkdir -p /go/src/github.com/hashicorp && cd /go/src/github.com/hashicorp && \
    git clone https://github.com/hashicorp/consul && cd consul && \
    git checkout $CONSUL_VERSION && \
    make dev && \
    yum remove -y git make gcc wget && \
    rm -rf $GOPATH/src $GOPATH/pkg && \
    rm -rf  /usr/local/go
    
# tiny smoke test to ensure the binary we downloaded runs
RUN consul version

# The /consul/data dir is used by Consul to store state. The agent will be started
# with /consul/config as the configuration directory so you can add additional
# config files in that location.
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