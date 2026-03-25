FROM registry.access.redhat.com/ubi9/ubi:9.7 as build
ARG TARGETARCH
ARG GO_VERSION=1.24.8

ENV GOPATH=/go
ENV CGO_ENABLED=0
ENV PATH=$PATH:/usr/local/go/bin:/go/bin
ENV PACKAGE_NAME=minio
ENV PACKAGE_VERSION=RELEASE.2025-10-15T17-29-55Z
ENV PATCH_FILE=https://raw.githubusercontent.com/ppc64le/build-scripts/master/m/minio/minio-${PACKAGE_VERSION}.patch

WORKDIR /build

# Install dependencies
RUN dnf install -y \
        git \
        curl-devel \
        tar \
        make \
        wget \
        gzip \
        ca-certificates \
    && dnf clean all

RUN wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz && \
    tar -C /usr/local -xzf go$GO_VERSION.linux-ppc64le.tar.gz && \
    mkdir -p /home/tester/go/src && \
    rm -f go$GO_VERSION.linux-ppc64le.tar.gz

# -------------------------
# Build MinIO
# -------------------------
COPY minio_changes.patch /build/

RUN git clone https://github.com/minio/minio.git && \
    cd ${PACKAGE_NAME} && \
    git checkout ${PACKAGE_VERSION} && \
    git apply /build/minio_changes.patch 

RUN cp /build/minio/dockerscripts/docker-entrypoint.sh /usr/bin/docker-entrypoint.sh

WORKDIR /build/minio

RUN make build && \
    make install 

# --------------------------------
# Runtime stage
# --------------------------------
FROM registry.access.redhat.com/ubi9/ubi-micro:latest

ENV MINIO_ACCESS_KEY_FILE=access_key \
    MINIO_SECRET_KEY_FILE=secret_key \
    MINIO_ROOT_USER_FILE=access_key \
    MINIO_ROOT_PASSWORD_FILE=secret_key \
    MINIO_KMS_SECRET_KEY_FILE=kms_master_key \
    MINIO_CONFIG_ENV_FILE=config.env \
    MC_CONFIG_DIR=/tmp/.mc

RUN chmod -R 777 /usr/bin

# Copy compiled binaries
COPY --from=build /go/bin/minio /usr/bin/minio

WORKDIR /build/minio
COPY --from=build /build/minio/CREDITS /licenses/CREDITS
COPY --from=build /build/minio/LICENSE /licenses/LICENSE
COPY --from=build /build/minio/dockerscripts/docker-entrypoint.sh /usr/bin/docker-entrypoint.sh

EXPOSE 9000
VOLUME ["/data"]

ENTRYPOINT ["/usr/bin/docker-entrypoint.sh"]
CMD ["minio"]
