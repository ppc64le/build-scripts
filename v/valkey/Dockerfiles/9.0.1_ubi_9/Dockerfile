FROM registry.access.redhat.com/ubi9/ubi-minimal:9.6 AS base

# =========================
# Build stage
# =========================
FROM base AS build

ENV VALKEY_VERSION=9.0.1
ENV VALKEY_DOWNLOAD_SHA=9cfbc5f32a2a6058ee0f8c532b9c4d24167cc49d719f091dd75f1bb8353a1fc5

ADD https://github.com/valkey-io/valkey/archive/refs/tags/9.0.1.tar.gz /valkey.tar.gz

RUN set -eux; \
    \
    # Enable required repos and install build dependencies
    microdnf update -y && \
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
    && microdnf clean all; \
    \
    # Verify source checksum
    echo "${VALKEY_DOWNLOAD_SHA}  /valkey.tar.gz" | sha256sum -c -; \
    \
    mkdir -p /usr/src/valkey; \
    tar -xzf /valkey.tar.gz -C /usr/src/valkey --strip-components=1; \
    rm -f /valkey.tar.gz; \
    \
    # ------------------------------------------------------------
    # Disable Valkey protected mode [1] as it is unnecessary in context of Docker
    #(Ports are not automatically exposed when running inside Docker, but rather explicitly by specifying -p / -P)
    # ------------------------------------------------------------
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
	
    # for future reference, we modify this directly in the source instead of just supplying a default configuration flag because apparently "if you specify any argument to valkey-server, [it assumes] you are going to specify everything"
    # (more exactly, this makes sure the default behavior of "save on SIGTERM" stays functional by default)
    # ------------------------------------------------------------
    # Patch jemalloc configure flags for RHEL / ppc64le
    # ------------------------------------------------------------
    # https://github.com/jemalloc/jemalloc/issues/467 -- we need to patch the "./configure" for the bundled jemalloc to match how Debian compiles, for compatibility
    # (also, we do cross-builds, so we need to embed the appropriate "--build=xxx" values to that "./configure" invocation)
	
    gnuArch="$(gcc -dumpmachine)"; \
    extraJemallocConfigureFlags="--build=${gnuArch}"; \
    \
	
	# https://salsa.debian.org/debian/jemalloc/-/blob/c0a88c37a551be7d12e4863435365c9a6a51525f/debian/rules#L8-23
	# dpkgArch="$(dpkg --print-architecture)"; \
	# case "${dpkgArch##*-}" in \
	#	amd64 | i386 | x32) extraJemallocConfigureFlags="$extraJemallocConfigureFlags --with-lg-page=12" ;; \
	#	*)
	
    # ppc64le uses 64K pages
	
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
    make -C /usr/src/valkey install; \
    \
	
    # ------------------------------------------------------------
    # Deduplicate binaries (symlinks)
    # ------------------------------------------------------------
    serverMd5="$(md5sum /usr/local/bin/valkey-server | awk '{print $1}')"; \
    export serverMd5; \
    \
    find /usr/local/bin/valkey* -maxdepth 0 \
        -type f -not -name valkey-server \
        -exec sh -eux -c ' \
            md5="$(md5sum "$1" | awk "{print \$1}")"; \
            test "$md5" = "$serverMd5"; \
        ' -- '{}' ';' \
        -exec ln -svfT valkey-server '{}' ';'; \
    \
    # ------------------------------------------------------------
    # Generate SBOM
    # ------------------------------------------------------------
    echo '{"spdxVersion":"SPDX-2.3","SPDXID":"SPDXRef-DOCUMENT","name":"valkey-server-sbom","packages":[{"name":"valkey-server","versionInfo":"9.0.1","SPDXID":"SPDXRef-Package--valkey-server","externalRefs":[{"referenceCategory":"PACKAGE-MANAGER","referenceType":"purl","referenceLocator":"pkg:generic/valkey-server@9.0.1?os_name=rhel&os_version=9"}],"licenseDeclared":"BSD-3-Clause"}]}' \
    > /usr/local/valkey.spdx.json

# =========================
# Runtime stage
# =========================
FROM registry.access.redhat.com/ubi9/ubi-minimal:9.6

ENV VALKEY_VERSION=9.0.1

LABEL org.opencontainers.image.source="https://github.com/valkey-io/valkey"

# Create valkey user/group
RUN set -eux; \
    groupadd -r -g 999 valkey; \
    useradd -r -g valkey -u 999 valkey


# Runtime dependencies only
RUN set -eux; \
    microdnf update -y && \ 
    microdnf install -y \
        tzdata \
        openssl-libs \
        libatomic \
        util-linux \
    && microdnf clean all

# Copy Valkey from build stage
COPY --from=build /usr/local /usr/local

RUN mkdir /data && \
    chown valkey:valkey /data && \
    mkdir -p /run/valkey && \
    chown valkey:valkey /run/valkey && \
    valkey-cli --version && \
    valkey-server --version

WORKDIR /data

COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 6379
CMD ["valkey-server"]
