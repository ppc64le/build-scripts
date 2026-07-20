# ==================================================
# Stage 1: Build required dependency (wait-for-port)
# ==================================================
FROM registry.access.redhat.com/ubi9/ubi-minimal:9.6 AS wfpbuilder

WORKDIR /src

# Install required tools for Go installation
RUN microdnf update -y && microdnf install -y \
        wget \
        git \
        tar \
    && microdnf clean all

# Install Go 1.25.5
RUN wget https://golang.org/dl/go1.25.5.linux-ppc64le.tar.gz && \
    tar -C /usr/local -xzf go1.25.5.linux-ppc64le.tar.gz && \
    rm -f go1.25.5.linux-ppc64le.tar.gz

ENV PATH=/usr/local/go/bin:$PATH

RUN git clone https://github.com/bitnami/wait-for-port && \
    cd wait-for-port && \
    git checkout v1.0.10 && \
    go build .

# =====================================
# Stage 2: Valkey build stage (ppc64le)
# =====================================
FROM registry.access.redhat.com/ubi9/ubi-minimal:9.6 AS valkeybuilder

ENV VALKEY_VERSION=9.0.1
ENV VALKEY_DOWNLOAD_SHA=9cfbc5f32a2a6058ee0f8c532b9c4d24167cc49d719f091dd75f1bb8353a1fc5

ADD https://github.com/valkey-io/valkey/archive/refs/tags/${VALKEY_VERSION}.tar.gz /valkey.tar.gz

RUN set -eux; \
    microdnf upgrade -y && \
    microdnf install -y \
        gcc \
        gcc-c++ \
        make \
        glibc-devel \
        openssl-devel \
        systemd-devel \
        redhat-rpm-config \
        shadow-utils \
        findutils \
        which \
        tar \
        gzip \
        libatomic \
    && microdnf clean all; \
    \
    echo "${VALKEY_DOWNLOAD_SHA}  /valkey.tar.gz" | sha256sum -c -; \
    \
    mkdir -p /usr/src/valkey; \
    tar -xzf /valkey.tar.gz -C /usr/src/valkey --strip-components=1; \
    rm -f /valkey.tar.gz; \
    \
    # Disable protected mode by default
    grep -E '^ *createBoolConfig[(]"protected-mode",.*, *1 *,.*[)],$' \
        /usr/src/valkey/src/config.c; \
    \
    sed -ri \
        's!^( *createBoolConfig[(]"protected-mode",.*, *)1( *,.*[)],)$!\10\2!' \
        /usr/src/valkey/src/config.c; \
    \
    grep -E '^ *createBoolConfig[(]"protected-mode",.*, *0 *,.*[)],$' \
        /usr/src/valkey/src/config.c; \
    \

    # Jemalloc tuning for ppc64le
    gnuArch="$(gcc -dumpmachine)"; \
        extraJemallocConfigureFlags="--build=${gnuArch}"; \
        \
    extraJemallocConfigureFlags="${extraJemallocConfigureFlags} --with-lg-page=16"; \
    extraJemallocConfigureFlags="${extraJemallocConfigureFlags} --with-lg-hugepage=21"; \
    \
         grep -F 'cd jemalloc && ./configure ' /usr/src/valkey/deps/Makefile; \
    \
    sed -ri \
        's!cd jemalloc && ./configure !&'"${extraJemallocConfigureFlags}"' !' \
        /usr/src/valkey/deps/Makefile; \
    \
        grep -F \
        "cd jemalloc && ./configure ${extraJemallocConfigureFlags} " \
        /usr/src/valkey/deps/Makefile; \
    \
    # ------------------------------------------------------------
    # Build Valkey
    # ------------------------------------------------------------
    echo "Version ${VALKEY_VERSION} >= 8.1 – enabling USE_FAST_FLOAT"; \
    \
    export BUILD_TLS=yes; \
    export USE_FAST_FLOAT=yes; \
    export USE_SYSTEMD=yes; \
    \
    make -C /usr/src/valkey -j"$(nproc)" all; \
    make -C /usr/src/valkey install PREFIX=/opt/bitnami/valkey; \
    \
    # Deduplicate binaries (Bitnami-style)
    serverMd5="$(md5sum /opt/bitnami/valkey/bin/valkey-server | awk '{print $1}')"; \
    export serverMd5; \
        \
    find /opt/bitnami/valkey/bin/valkey* -maxdepth 0 \
      -type f -not -name valkey-server \
      -exec sh -eux -c ' \
            md5="$(md5sum "$1" | awk "{print \$1}")"; \
            test "$md5" = "$serverMd5"; \
        ' -- '{}' ';' \
        -exec ln -svfT valkey-server '{}' ';';

# -------------------------------
# Stage 3: Fetch Bitnami sources
# -------------------------------
FROM registry.access.redhat.com/ubi9/ubi-minimal:9.6 AS fetch

RUN microdnf install -y git wget tar \
 && microdnf clean all
 
WORKDIR /tmp

ENV BITNAMI_VALKEY_COMMIT=92a02fc
ENV VALKEY_VERSION=9.0.1 
RUN git clone https://github.com/bitnami/containers.git \
 && cd containers \
 && git checkout ${BITNAMI_VALKEY_COMMIT} \
 && wget -q https://downloads.bitnami.com/files/stacksmith/valkey-${VALKEY_VERSION}-0-linux-amd64-debian-12.tar.gz \
 && tar -xf valkey-${VALKEY_VERSION}-0-linux-amd64-debian-12.tar.gz \
 && mkdir -p /tmp/containers/bitnami/valkey/9.0/debian-12/prebuildfs/opt/bitnami/valkey/etc \
 && cp valkey-*/files/valkey/etc/valkey-default.conf \
       /tmp/containers/bitnami/valkey/9.0/debian-12/prebuildfs/opt/bitnami/valkey/etc/ \
 && cp -a /tmp/containers/bitnami/valkey/9.0/debian-12/prebuildfs /tmp/prebuildfs \	
 && cp -a /tmp/containers/bitnami/valkey/9.0/debian-12/rootfs /tmp/rootfs

	   
# -----------------------------
# Stage 4: Runtime Stage
# -----------------------------
FROM registry.access.redhat.com/ubi9/ubi-minimal:9.6

LABEL org.opencontainers.image.documentation="https://github.com/bitnami/containers/tree/main/bitnami/valkey/README.md" \
      org.opencontainers.image.source="https://github.com/bitnami/containers/tree/main/bitnami/valkey" \
      org.opencontainers.image.title="valkey" \
      org.opencontainers.image.version="9.0.1"

ENV HOME="/" \
    OS_ARCH="ppc64le" \
    OS_FLAVOUR="rhel9" \
    OS_NAME="linux"

# ---- Copy Bitnami filesystem ----
COPY --from=fetch /tmp/prebuildfs/ /

SHELL ["/bin/bash", "-o", "errexit", "-o", "nounset", "-o", "pipefail", "-c"]
RUN microdnf upgrade -y \
 && microdnf install -y \
        ca-certificates \
        curl-minimal \
        libgomp \
        openssl-libs \
        procps-ng \
        libatomic \
        util-linux \
        tzdata \
 && microdnf clean all \
 && rm -rf /var/cache/yum /var/tmp/*

RUN chmod g+rwX /opt/bitnami
RUN find / -perm /6000 -type f -exec chmod a-s {} \; || true
RUN ln -s /opt/bitnami/scripts/valkey/entrypoint.sh /entrypoint.sh
RUN ln -s /opt/bitnami/scripts/valkey/run.sh /run.sh

COPY --from=fetch /tmp/rootfs/ /
RUN /opt/bitnami/scripts/valkey/postunpack.sh
RUN mkdir -p /opt/bitnami/common/bin
RUN chmod g+rwX /opt/bitnami
COPY --from=wfpbuilder /src/wait-for-port/wait-for-port /opt/bitnami/common/bin
COPY --from=valkeybuilder /opt/bitnami/valkey /opt/bitnami/valkey

ENV APP_VERSION="9.0.1" \
    BITNAMI_APP_NAME="valkey" \
    IMAGE_REVISION="2" \
    PATH="/opt/bitnami/common/bin:/opt/bitnami/valkey/bin:$PATH"

EXPOSE 6379

USER 1001
ENTRYPOINT [ "/opt/bitnami/scripts/valkey/entrypoint.sh" ]
CMD [ "/opt/bitnami/scripts/valkey/run.sh" ]
