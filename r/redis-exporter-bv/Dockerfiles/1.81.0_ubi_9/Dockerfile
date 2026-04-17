FROM registry.access.redhat.com/ubi9/ubi-minimal:9.7 AS prebuild

ARG BITNAMI_COMMIT=73a3eae6455fbc6d38b69198b4cb0195adee69c1

RUN microdnf update -y && \
    microdnf install -y git && \
    microdnf clean all

WORKDIR /tmp

# Clone only latest snapshot (shallow clone)
RUN git clone --depth 1 https://github.com/bitnami/containers.git && \
    cd /build/containers && \
    git checkout ${BITNAMI_COMMIT}

# Move only required folder to a clean location
RUN cp -r containers/bitnami/redis-exporter/1/debian-12/prebuildfs /prebuildfs


FROM registry.access.redhat.com/ubi9/ubi-minimal:9.7

LABEL org.opencontainers.image.documentation="https://github.com/bitnami/containers/tree/main/bitnami/redis-exporter/README.md" \
      org.opencontainers.image.source="https://github.com/bitnami/containers/tree/main/bitnami/redis-exporter" \
      org.opencontainers.image.title="redis-exporter" \
      org.opencontainers.image.version="1.81.0"

ENV HOME="/" \
    OS_ARCH="ppc64le" \
    OS_FLAVOUR="rhel9" \
    OS_NAME="linux"


RUN microdnf update -y && \
    microdnf install -y wget gzip ca-certificates curl-minimal procps tar && \
    microdnf clean all 

RUN mkdir -p /opt/bitnami/redis-exporter/bin

RUN mkdir -p /opt/bitnami/redis-exporter/licenses && \
    wget -q https://raw.githubusercontent.com/oliver006/redis_exporter/v1.81.0/LICENSE \
    -O /opt/bitnami/redis-exporter/licenses/redis-exporter-1.81.0.txt

RUN wget -q https://github.com/oliver006/redis_exporter/releases/download/v1.81.0/redis_exporter-v1.81.0.linux-ppc64le.tar.gz && \
    tar -zxf redis_exporter-v1.81.0.linux-ppc64le.tar.gz && \
    mv redis_exporter-v1.81.0.linux-ppc64le/redis_exporter /opt/bitnami/redis-exporter/bin/redis_exporter && \
    rm -rf redis_exporter-v1.81.0.linux-ppc64le*

# Copy filesystem overlays
COPY --from=prebuild /prebuildfs /

RUN chmod g+rwX /opt/bitnami

ENV APP_VERSION="1.81.0" \
    BITNAMI_APP_NAME="redis-exporter" \
    IMAGE_REVISION="0" \
    PATH="/opt/bitnami/redis-exporter/bin:$PATH"

EXPOSE 9121

WORKDIR /opt/bitnami/redis-exporter
USER 1001
ENTRYPOINT [ "redis_exporter" ]
