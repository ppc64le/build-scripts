# SPDX-License-Identifier: APACHE-2.0

FROM registry.access.redhat.com/ubi9/ubi-minimal:9.8 as builder
# This docker file is generated on basis of "https://github.com/bitnami/containers/commit/a070c76096f392602981e115a401be85d58e2c0b"

ARG GO_VERSION=1.24.9
RUN microdnf -y update \
    && microdnf install -y glibc-devel glibc-headers gcc-c++ git make cmake findutils wget tar \
    && wget https://go.dev/dl/go${GO_VERSION}.linux-ppc64le.tar.gz \
    && tar -C /usr/local -xf go${GO_VERSION}.linux-ppc64le.tar.gz

ENV GOROOT=/usr/local/go
ENV GOPATH=$HOME
ENV PATH=$GOPATH/bin:$GOROOT/bin:$PATH

RUN cd /root && git clone https://github.com/bitnami/wait-for-port && cd wait-for-port/ \
    && git checkout v1.0.10 && go build .

RUN cd /root && wget https://github.com/tianon/gosu/releases/download/1.17/gosu-ppc64el && mv gosu-ppc64el gosu && chmod +x /root/gosu

ARG SHORT_DISTRO_NAME=zookeeper-3.9.5
ARG DISTRO_NAME=apache-zookeeper-3.9.5-bin

LABEL org.opencontainers.image.base.name="registry.access.redhat.com/ubi9/ubi-minimal:9.8" \
      org.opencontainers.image.documentation="https://github.com/bitnami/containers/tree/main/bitnami/zookeeper/README.md" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.ref.name="3.9.5-debian-12-r0" \
      org.opencontainers.image.source="https://github.com/bitnami/containers/tree/main/bitnami/zookeeper" \
      org.opencontainers.image.title="zookeeper" \
      org.opencontainers.image.version="3.9.5"


# Download Apache ZooKeeper, untar and clean up
RUN set -eux; \
    ddist() { \
        local f="$1"; shift; \
        local distFile="$1"; shift; \
        local success=; \
        local distUrl=; \
        for distUrl in \
            'https://www.apache.org/dyn/closer.cgi?action=download&filename=' \
            https://www-us.apache.org/dist/ \
            https://www.apache.org/dist/ \
            https://archive.apache.org/dist/ \
        ; do \
            if wget -q -O "$f" "$distUrl$distFile" && [ -s "$f" ]; then \
                success=1; \
                break; \
            fi; \
        done; \
        [ -n "$success" ]; \
    }; \
    cd /root; \
    ddist "$DISTRO_NAME.tar.gz" "zookeeper/$SHORT_DISTRO_NAME/$DISTRO_NAME.tar.gz"; \
    ddist "$DISTRO_NAME.tar.gz.asc" "zookeeper/$SHORT_DISTRO_NAME/$DISTRO_NAME.tar.gz.asc"; \
    tar -zxf "$DISTRO_NAME.tar.gz"; \
    rm -rf "$DISTRO_NAME.tar.gz" "$DISTRO_NAME.tar.gz.asc"; \
    mv $DISTRO_NAME zookeeper; \
    chown -R root:root zookeeper

# Download Java 11
RUN cd /root \
&& wget https://github.com/adoptium/temurin11-binaries/releases/download/jdk-11.0.30%2B9/OpenJDK11U-jdk_ppc64le_linux_hotspot_11.0.30_9.tar.gz \
&& tar xzf OpenJDK11U-jdk_ppc64le_linux_hotspot_11.0.30_9.tar.gz \
&& mv jdk-11.0.30+9 java


FROM registry.access.redhat.com/ubi9/ubi-minimal:9.8
LABEL maintainer "Amit Kumar <amit.kumar282@ibm.com>"

ENV HOME="/" \
    OS_ARCH="ppc64le" \
    OS_FLAVOUR="rhel9" \
    OS_NAME="linux" \
    PATH="/opt/bitnami/common/bin:/opt/bitnami/java/bin:/opt/bitnami/zookeeper/bin:$PATH"

COPY prebuildfs /
SHELL ["/bin/bash", "-o", "errexit", "-o", "nounset", "-o", "pipefail", "-c"]

# Install required system packages and dependencies
RUN microdnf -y update && \
    microdnf install -y ca-certificates curl-minimal nmap-ncat procps xmlstarlet zlib gzip openssl glibc-devel hostname nc && \
    microdnf clean all && \
    rm -rf /var/cache/dnf /var/tmp/*

RUN chmod g+rwX /opt/bitnami
RUN find / -perm /6000 -type f -exec chmod a-s {} \; || true
RUN ln -s /opt/bitnami/scripts/zookeeper/entrypoint.sh /entrypoint.sh
RUN ln -s /opt/bitnami/scripts/zookeeper/run.sh /run.sh

COPY rootfs /
RUN mkdir -p /opt/bitnami/common/bin
COPY --from=builder /root/wait-for-port/wait-for-port /opt/bitnami/common/bin
COPY --from=builder /root/zookeeper /opt/bitnami/zookeeper
COPY --from=builder /root/java /opt/bitnami/java
COPY --from=builder /root/gosu /opt/bitnami/common/bin/gosu
RUN ls /opt/bitnami/common/bin && ls /opt/bitnami/zookeeper/bin/
RUN /opt/bitnami/scripts/zookeeper/postunpack.sh

ENV APP_VERSION="3.9.5" \
    BITNAMI_APP_NAME="zookeeper" \
    IMAGE_REVISION="0"

EXPOSE 2181 2888 3888 8080

USER 1001
ENTRYPOINT [ "/opt/bitnami/scripts/zookeeper/entrypoint.sh" ]
CMD [ "/opt/bitnami/scripts/zookeeper/run.sh" ]
