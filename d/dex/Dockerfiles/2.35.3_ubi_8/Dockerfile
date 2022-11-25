FROM registry.access.redhat.com/ubi8/ubi:latest

ARG PACKAGE_VERSION=v2.35.3

RUN yum install -y git make golang && \
        git clone $PACKAGE_URL && \
        cd $PACKAGE_NAME && \
        git checkout $PACKAGE_VERSION && \
        make build && \
        yum remove -y git

ENTRYPOINT ["/dex/cmd/docker-entrypoint"]
CMD ["dex", "serve", "/dex/config.docker.yaml"]