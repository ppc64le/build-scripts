# Copyright Broadcom, Inc. All Rights Reserved.
# SPDX-License-Identifier: APACHE-2.0

# Stage 1: Build utilities from source using secure Go version (resolves stdlib CVEs)
FROM registry.access.redhat.com/ubi9/ubi:9.7 AS setupbuilder

ARG REDIS_VERSION=8.4.1
ARG BITNAMI_COMMIT=83fa2f7
ARG GO_VERSION=1.26.2

# Install build dependencies and update system packages
RUN yum update -y && yum install -y git wget tar gcc && yum clean all

# Install secure Go version to fix stdlib CVEs (CVE-2025-68121, CVE-2025-58183, etc.)
RUN wget -q https://go.dev/dl/go${GO_VERSION}.linux-ppc64le.tar.gz && \
    tar -C /usr/local -xzf go${GO_VERSION}.linux-ppc64le.tar.gz && \
    rm go${GO_VERSION}.linux-ppc64le.tar.gz

ENV PATH="/usr/local/go/bin:$PATH"

# Build wait-for-port from source
RUN git clone https://github.com/bitnami/wait-for-port /build/wait-for-port && \
    cd /build/wait-for-port && \
    git checkout v1.0.10 && \
    go build .

# Build gosu from source with secure Go version (fixes 8 stdlib CVEs in pre-compiled binary)
RUN cd /build && \
    git clone https://github.com/tianon/gosu && \
    cd gosu && \
    git checkout 1.19 && \
    CGO_ENABLED=0 go build -o gosu .

# Assemble prebuildfs
RUN git clone https://github.com/bitnami/containers /build/containers && \
    cd /build/containers && \
    git checkout ${BITNAMI_COMMIT}

RUN cd /build/containers/bitnami/redis/8.4/debian-12 && \
    wget https://downloads.bitnami.com/files/stacksmith/redis-${REDIS_VERSION}-0-linux-amd64-debian-12.tar.gz && \
    tar -xvf redis-${REDIS_VERSION}-0-linux-amd64-debian-12.tar.gz && \
    mkdir -p prebuildfs/opt/bitnami/redis/etc && \
    cp redis-${REDIS_VERSION}-linux-amd64-debian-12/files/redis/etc/redis-default.conf \
       prebuildfs/opt/bitnami/redis/etc/

FROM registry.access.redhat.com/ubi9/ubi:9.7 AS redisbuilder

WORKDIR /build

RUN yum update -y && \
    yum install -y \
    git \
    gcc \
    gcc-c++ \
    make \
    autoconf \
    automake \
    libtool \
    diffutils \
    tcl \
    procps-ng \
    libstdc++-devel \
    patch \
    cmake \
    python3 \
    python3-devel \
    openssl-devel \
    rust \
    cargo \
    clang-devel \
    util-linux \
    llvm-devel && \
    yum update -y python3 python3-libs openssh openssh-clients vim-minimal libarchive libcap && \
    yum clean all && \
    rm -rf /var/cache/yum

COPY redis-bv_8.4.1.patch /build/

RUN cd /build && \
    git clone https://github.com/redis/redis && \
    cd redis && \
    git checkout 8.4.1 && \
    patch -p1 < /build/redis-bv_8.4.1.patch

# Fix modules/Makefile - Add ppc64le Rust support
RUN cd /build/redis && python3 << 'EOF'
content = open('modules/Makefile').read()
old = "\t\t\tfi ;; \\\n\t\t*) echo"
new = "\t\t\tfi ;; \\\n\t\t'ppc64le') \\\n\t\t\tRUST_INSTALLER=\"rust-$${RUST_VERSION}-powerpc64le-unknown-linux-gnu\"; \\\n\t\t\tRUST_SHA256=\"\"; \\\n\t\t\t;; \\\n\t\t*) echo"
assert old in content, "NO MATCH - modules/Makefile"
open('modules/Makefile', 'w').write(content.replace(old, new))
print("OK")
EOF

# Fix modules/common.mk - Add ppc64le arch map
RUN cd /build/redis && python3 << 'EOF'
content = open('modules/common.mk').read()
old = "ARCH_MAP_aarch64 := arm64v8\nARCH_MAP_arm64 := arm64v8"
new = "ARCH_MAP_aarch64 := arm64v8\nARCH_MAP_arm64 := arm64v8\nARCH_MAP_ppc64le := ppc64le"
assert old in content, "NO MATCH - common.mk"
open('modules/common.mk', 'w').write(content.replace(old, new))
print("OK")
EOF

# Ensure python3 is available in PATH for module builds (RedisJSON and RedisTimeSeries need it)
RUN which python3 && python3 --version && \
    mkdir -p /usr/local/bin && \
    ln -sf /usr/bin/python3 /usr/local/bin/python3 && \
    ln -sf /usr/bin/python3 /usr/local/bin/python && \
    ln -sf /usr/bin/python3 /usr/bin/python && \
    which python3 && which python && \
    python3 --version && python --version

RUN cd /build/redis && \
    EXTRA_CFLAGS="" && \
    if [[ $(uname -m) == "ppc64le" ]]; then \
        if grep -iq "POWER10" /proc/cpuinfo || lscpu | grep -iq "POWER10"; then \
            echo ">>> Power10 CPU detected. Applying P10 optimization flags..." && \
            EXTRA_CFLAGS="-mcpu=power10 -mtune=power10"; \
        fi \
    fi && \
    export BUILD_WITH_MODULES=yes && \
    export DISABLE_WERRORS=yes && \
    unset INSTALL_RUST_TOOLCHAIN && \
    make MALLOC=libc EXTRA_CFLAGS="$EXTRA_CFLAGS" -j "$(nproc)" all IGNORE_MISSING_DEPS=1 || true

# Fix redisearch - Remove duplicate RS_FIELDMASK_ALL
RUN cd /build/redis && python3 << 'EOF'
path = 'modules/redisearch/src/src/redisearch_rs/ffi/src/lib.rs'
content = open(path).read()
old = "pub const RS_FIELDMASK_ALL: FieldMask = u128::MAX;\n"
assert old in content, "NO MATCH - ffi/src/lib.rs"
open(path, 'w').write(content.replace(old, ""))
print("OK")
EOF

# Fix redisearch - FieldMask type in fields_only.rs
RUN cd /build/redis && python3 << 'EOF'
path = 'modules/redisearch/src/src/redisearch_rs/inverted_index/src/fields_only.rs'
content = open(path).read()
old = "let field_mask = u128::read_as_varint(cursor)?;"
new = "let field_mask = u64::read_as_varint(cursor)?;"
assert old in content, "NO MATCH - fields_only.rs"
open(path, 'w').write(content.replace(old, new))
print("OK")
EOF

# Fix redisearch - RS_FIELDMASK_ALL cast in index_result.rs
RUN cd /build/redis && python3 << 'EOF'
path = 'modules/redisearch/src/src/redisearch_rs/inverted_index/src/index_result.rs'
content = open(path).read()
count = content.count("field_mask: RS_FIELDMASK_ALL,")
assert count > 0, "NO MATCH - index_result.rs"
open(path, 'w').write(content.replace("field_mask: RS_FIELDMASK_ALL,", "field_mask: RS_FIELDMASK_ALL as t_fieldMask,"))
print(f"OK - Replaced {count} occurrences")
EOF

# Fix VectorSimilarity - Add ppc64le CPU features support
RUN cd /build/redis && python3 << 'EOF'
path = 'modules/redisearch/src/deps/VectorSimilarity/src/VecSim/spaces/spaces.h'
content = open(path).read()
old = """#if defined(CPU_FEATURES_ARCH_AARCH64)
    using FeaturesType = cpu_features::Aarch64Features;
    constexpr auto getFeatures = cpu_features::GetAarch64Info;
#else
    using FeaturesType = cpu_features::X86Features; // Fallback
    constexpr auto getFeatures = cpu_features::GetX86Info;
#endif
    return arch_opt ? *static_cast<const FeaturesType *>(arch_opt) : getFeatures().features;"""
new = """#if defined(CPU_FEATURES_ARCH_AARCH64)
    using FeaturesType = cpu_features::Aarch64Features;
    constexpr auto getFeatures = cpu_features::GetAarch64Info;
    return arch_opt ? *static_cast<const FeaturesType *>(arch_opt) : getFeatures().features;
#elif defined(__powerpc64__)
    struct EmptyFeatures {};
    return EmptyFeatures{};
#else
    using FeaturesType = cpu_features::X86Features; // Fallback
    constexpr auto getFeatures = cpu_features::GetX86Info;
    return arch_opt ? *static_cast<const FeaturesType *>(arch_opt) : getFeatures().features;
#endif"""
assert old in content, "NO MATCH - spaces.h"
open(path, 'w').write(content.replace(old, new))
print("OK")
EOF

# Final build with all fixes applied
RUN cd /build/redis && \
    EXTRA_CFLAGS="" && \
    if [[ $(uname -m) == "ppc64le" ]]; then \
        if grep -iq "POWER10" /proc/cpuinfo || lscpu | grep -iq "POWER10"; then \
            echo ">>> Power10 CPU detected. Applying P10 optimization flags..." && \
            EXTRA_CFLAGS="-mcpu=power10 -mtune=power10"; \
        fi \
    fi && \
    export BUILD_WITH_MODULES=yes && \
    export DISABLE_WERRORS=yes && \
    export PATH="/usr/bin:/usr/local/bin:$PATH" && \
    export PYTHON3=/usr/bin/python3 && \
    export PYTHON=/usr/bin/python3 && \
    unset INSTALL_RUST_TOOLCHAIN && \
    which python3 && python3 --version && \
    python3 -c "import sys; print(sys.executable)" && \
    make MALLOC=libc EXTRA_CFLAGS="$EXTRA_CFLAGS" -j "$(nproc)" all IGNORE_MISSING_DEPS=1

# Collect Redis binaries and all 4 modules
RUN find /build/redis/modules -maxdepth 2 -name "*.so" | grep -v "deps\|src/bin\|target" && \
    mkdir -p /root/redis/bin /root/redis/modules && \
    find /build/redis/src -maxdepth 1 -type f -executable -name "redis-*" -exec cp {} /root/redis/bin/ \; && \
    cp /build/redis/modules/redisbloom/redisbloom.so /root/redis/modules/ && \
    cp /build/redis/modules/redisearch/redisearch.so /root/redis/modules/ && \
    cp /build/redis/modules/redisjson/rejson.so /root/redis/modules/ && \
    cp /build/redis/modules/redistimeseries/redistimeseries.so /root/redis/modules/ && \
    ls -lh /root/redis/bin/ /root/redis/modules/

# Erase Python RPM packages after build is complete (not needed in final image)
RUN yum clean all && \
    rm -rf /var/cache/yum && \
    rpm -e --nodeps python3 python3-devel python3-libs

FROM registry.access.redhat.com/ubi9/ubi:9.7
LABEL com.vmware.cp.artifact.flavor="sha256:c50c90cfd9d12b445b011e6ad529f1ad3daea45c26d20b00732fae3cd71f6a83" \
      org.opencontainers.image.documentation="https://github.com/bitnami/containers/tree/main/bitnami/redis/README.md" \
      org.opencontainers.image.source="https://github.com/bitnami/containers/tree/main/bitnami/redis" \
      org.opencontainers.image.title="redis" \
      org.opencontainers.image.version="8.4.1"

ENV HOME="/" \
    OS_ARCH="ppc64le" \
    OS_FLAVOUR="rhel9" \
    OS_NAME="linux"

COPY --from=setupbuilder /build/containers/bitnami/redis/8.4/debian-12/prebuildfs /
COPY --from=setupbuilder /build/containers/bitnami/redis/8.4/debian-12/rootfs /

# Install runtime dependencies and apply all security updates
RUN yum update -y && \
    yum install -y git wget acl ca-certificates curl-minimal gzip glibc openssl procps tar libgcc libgomp libstdc++ && \
    yum upgrade -y --allowerasing && \
    yum clean all && \
    rm -rf /var/cache/yum /var/tmp/* && \
    rpm -e --nodeps python3 python3-libs 2>/dev/null || true

RUN chmod g+rwX /opt/bitnami
RUN ln -s /opt/bitnami/scripts/redis/entrypoint.sh /entrypoint.sh
RUN ln -s /opt/bitnami/scripts/redis/run.sh /run.sh
RUN /opt/bitnami/scripts/redis/postunpack.sh
RUN mkdir -p /opt/bitnami/common/bin
RUN chmod g+rwX /opt/bitnami

# Copy utilities built from source with secure Go version (fixes gosu stdlib CVEs)
COPY --from=setupbuilder /build/wait-for-port/wait-for-port /opt/bitnami/common/bin/wait-for-port
COPY --from=setupbuilder /build/gosu/gosu /opt/bitnami/common/bin/gosu
COPY --from=redisbuilder  /root/redis/bin /opt/bitnami/redis/bin
COPY --from=redisbuilder  /root/redis/modules /opt/bitnami/redis/modules



# Create symlink directory for Bitnami Helm chart compatibility
# The Helm chart looks for modules at /opt/bitnami/redis/lib/redis/modules/
RUN mkdir -p /opt/bitnami/redis/lib/redis/modules && \
    cp /opt/bitnami/redis/modules/*.so /opt/bitnami/redis/lib/redis/modules/ && \
    ls -lh /opt/bitnami/redis/lib/redis/modules/

# Set executable permissions
RUN chmod +x /opt/bitnami/common/bin/gosu /opt/bitnami/common/bin/wait-for-port

ENV APP_VERSION="8.4.1" \
    BITNAMI_APP_NAME="redis" \
    IMAGE_REVISION="0" \
    PATH="/opt/bitnami/common/bin:/opt/bitnami/redis/bin:$PATH"

EXPOSE 6379
USER 1001
ENTRYPOINT [ "/opt/bitnami/scripts/redis/entrypoint.sh" ]
CMD [ "/opt/bitnami/scripts/redis/run.sh" ]
