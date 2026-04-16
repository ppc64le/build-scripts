# Copyright Broadcom, Inc. All Rights Reserved.
# SPDX-License-Identifier: APACHE-2.0
 
# Stage 1: Build utilities from source using secure Go version (resolves stdlib CVEs)
FROM registry.access.redhat.com/ubi9/ubi:9.7 AS builder
USER root
# Install build dependencies and a secure Go version (1.26.1) for ppc64le
ENV GO_VERSION="1.26.1"
RUN dnf update -y && dnf install -y git wget tar gcc && \
    wget -q https://golang.org/dl/go${GO_VERSION}.linux-ppc64le.tar.gz && \
    tar -C /usr/local -xzf go${GO_VERSION}.linux-ppc64le.tar.gz && \
    rm go${GO_VERSION}.linux-ppc64le.tar.gz

ENV PATH="/usr/local/go/bin:$PATH"

# Build wait-for-port utility from source
RUN mkdir -p /root/build && cd /root/build && \
    git clone https://github.com/bitnami/wait-for-port && \
    cd wait-for-port/ && \
    git checkout v1.0.10 && \
    go build -o wait-for-port .

# Build gosu utility from source (to resolve stdlib CVEs in the pre-compiled binary)
RUN cd /root/build && \
    git clone https://github.com/tianon/gosu && \
    cd gosu && \
    git checkout 1.19 && \
    CGO_ENABLED=0 go build -o gosu .

# Stage 2: Build Redis-cluster (aligned with Broadcom/Bitnami 8.4.1 specification)
FROM registry.access.redhat.com/ubi9/ubi:9.7 AS redisbuilder

# Environmental variables for build consistency
ENV PACKAGE_VERSION="8.4.1" \
    BITNAMI_COMMIT_ID="8fe1092de5cf5664de9f8afc7764b51d69d4da86" \
    REDIS_URL="https://github.com/redis/redis" \
    BITNAMI_URL="https://github.com/bitnami/containers"

# Install build dependencies
RUN dnf update -y && \
    dnf install -y git wget tar make which procps hostname gcc gcc-c++ openssl openssl-devel ncurses ncurses-devel libstdc++ libstdc++-devel \
    python3 jq tcl diffutils patch autoconf automake libtool cmake python3-devel rust cargo clang-devel llvm-devel && \
    # Explicitly update vulnerable builder packages
    dnf update -y python3 openssh && \
    dnf clean all

WORKDIR /root

# Clone Bitnami repository for scripts and rootfs
RUN git clone ${BITNAMI_URL} redis-cluster && \
    cd redis-cluster && \
    git checkout ${BITNAMI_COMMIT_ID}

# Clone and Patch Redis source code with P10 optimization
COPY redis-8.4.1-ppc64le-fixed.patch /tmp/
RUN git clone ${REDIS_URL} redis && \
    cd redis && \
    git checkout ${PACKAGE_VERSION} && \
    git apply /tmp/redis-8.4.1-ppc64le-fixed.patch


# Fix modules/Makefile - Add ppc64le Rust support
RUN cd /root/redis && python3 << 'EOF'
content = open('modules/Makefile').read()
old = "\t\t\tfi ;; \\\n\t\t*) echo"
new = "\t\t\tfi ;; \\\n\t\t'ppc64le') \\\n\t\t\tRUST_INSTALLER=\"rust-$${RUST_VERSION}-powerpc64le-unknown-linux-gnu\"; \\\n\t\t\tRUST_SHA256=\"\"; \\\n\t\t\t;; \\\n\t\t*) echo"
assert old in content, "NO MATCH - modules/Makefile"
open('modules/Makefile', 'w').write(content.replace(old, new))
print("OK")
EOF

# Fix modules/common.mk - Add ppc64le arch map
RUN cd /root/redis && python3 << 'EOF'
content = open('modules/common.mk').read()
old = "ARCH_MAP_aarch64 := arm64v8\nARCH_MAP_arm64 := arm64v8"
new = "ARCH_MAP_aarch64 := arm64v8\nARCH_MAP_arm64 := arm64v8\nARCH_MAP_ppc64le := ppc64le"
assert old in content, "NO MATCH - common.mk"
open('modules/common.mk', 'w').write(content.replace(old, new))
print("OK")
EOF

# Ensure python3 is available in PATH for module builds (RedisJSON and RedisTimeSeries need it)
# Create symlinks and set up environment
RUN which python3 && python3 --version && \
    mkdir -p /usr/local/bin && \
    ln -sf /usr/bin/python3 /usr/local/bin/python3 && \
    ln -sf /usr/bin/python3 /usr/local/bin/python && \
    ln -sf /usr/bin/python3 /usr/bin/python && \
    which python3 && which python && \
    python3 --version && python --version

# Final build with all fixes applied 
RUN cd /root/redis && \
    EXTRA_CFLAGS="" && \
    if [[ $(uname -m) == "ppc64le" ]]; then \
        if grep -iq "POWER10" /proc/cpuinfo || lscpu | grep -iq "POWER10"; then \
            echo ">>> Power 10 CPU detected. Applying P10 optimization flags..." && \
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
    make MALLOC=libc -j "$(nproc)" all IGNORE_MISSING_DEPS=1 || true

# Fix redisearch - Remove duplicate RS_FIELDMASK_ALL
RUN cd /root/redis && python3 << 'EOF'
path = 'modules/redisearch/src/src/redisearch_rs/ffi/src/lib.rs'
content = open(path).read()
old = "pub const RS_FIELDMASK_ALL: FieldMask = u128::MAX;\n"
assert old in content, "NO MATCH - ffi/src/lib.rs"
open(path, 'w').write(content.replace(old, ""))
print("OK")
EOF

# Fix redisearch - FieldMask type in fields_only.rs
RUN cd /root/redis && python3 << 'EOF'
path = 'modules/redisearch/src/src/redisearch_rs/inverted_index/src/fields_only.rs'
content = open(path).read()
old = "let field_mask = u128::read_as_varint(cursor)?;"
new = "let field_mask = u64::read_as_varint(cursor)?;"
assert old in content, "NO MATCH - fields_only.rs"
open(path, 'w').write(content.replace(old, new))
print("OK")
EOF

# Fix redisearch - RS_FIELDMASK_ALL cast in index_result.rs
RUN cd /root/redis && python3 << 'EOF'
path = 'modules/redisearch/src/src/redisearch_rs/inverted_index/src/index_result.rs'
content = open(path).read()
count = content.count("field_mask: RS_FIELDMASK_ALL,")
assert count > 0, "NO MATCH - index_result.rs"
open(path, 'w').write(content.replace("field_mask: RS_FIELDMASK_ALL,", "field_mask: RS_FIELDMASK_ALL as t_fieldMask,"))
print(f"OK - Replaced {count} occurrences")
EOF

# Fix VectorSimilarity - Add ppc64le CPU features support
RUN cd /root/redis && python3 << 'EOF'
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
RUN cd /root/redis && \
    EXTRA_CFLAGS="" && \
    if [[ $(uname -m) == "ppc64le" ]]; then \
        if grep -iq "POWER10" /proc/cpuinfo || lscpu | grep -iq "POWER10"; then \
            echo ">>> Power 10 CPU detected. Applying P10 optimization flags..." && \
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
    make MALLOC=libc -j "$(nproc)" all IGNORE_MISSING_DEPS=1

# Collect ONLY the compiled .so module files (not source/deps/build artifacts)
RUN mkdir -p /root/modules-output && \
    cp /root/redis/modules/redisbloom/redisbloom.so /root/modules-output/ && \
    cp /root/redis/modules/redisearch/redisearch.so /root/modules-output/ && \
    cp /root/redis/modules/redisjson/rejson.so /root/modules-output/ && \
    cp /root/redis/modules/redistimeseries/redistimeseries.so /root/modules-output/ && \
    ls -lh /root/modules-output/

# Prepare artifacts directory structure - copy only necessary runtime files
RUN mkdir -p /root/output/opt/bitnami/redis/bin /root/output/opt/bitnami/redis/etc /root/output/opt/bitnami/common/bin && \
    cp /root/redis/src/redis-server /root/output/opt/bitnami/redis/bin/ && \
    cp /root/redis/src/redis-cli /root/output/opt/bitnami/redis/bin/ && \
    cp /root/redis/src/redis-benchmark /root/output/opt/bitnami/redis/bin/ && \
    cp /root/redis/src/redis-check-aof /root/output/opt/bitnami/redis/bin/ && \
    cp /root/redis/src/redis-check-rdb /root/output/opt/bitnami/redis/bin/ && \
    cp /root/redis/redis.conf /root/output/opt/bitnami/redis/etc/redis-default.conf && \
    cp -r /root/redis-cluster/bitnami/redis-cluster/8.4/debian-12/rootfs/* /root/output/ && \
    cp -r /root/redis-cluster/bitnami/redis-cluster/8.4/debian-12/prebuildfs/* /root/output/
    
# Stage 3: Final Production Image (UBI 9.7)
FROM registry.access.redhat.com/ubi9/ubi:9.7
 
LABEL org.opencontainers.image.base.name="registry.access.redhat.com/ubi9/ubi:9.7" \
      org.opencontainers.image.created="2026-04-10T12:00:00Z" \
      org.opencontainers.image.description="Redis Cluster optimized for Power10 with Bitnami scripts" \
      org.opencontainers.image.documentation="https://github.com/bitnami/containers/tree/main/bitnami/redis-cluster/README.md" \
      org.opencontainers.image.source="https://github.com/bitnami/containers/tree/main/bitnami/redis-cluster" \
      org.opencontainers.image.title="redis-cluster-ppc64le" \
      org.opencontainers.image.vendor="Broadcom, Inc." \
      org.opencontainers.image.version="8.4.1"
 
ENV HOME="/" \
    OS_ARCH="ppc64le" \
    OS_FLAVOUR="rhel-9" \
    OS_NAME="linux" \
    APP_VERSION="8.4.1" \
    BITNAMI_APP_NAME="redis-cluster" \
    IMAGE_REVISION="0"
 
# Runtime dependencies for RHEL 9
RUN dnf update -y && \
    dnf install -y --allowerasing ca-certificates curl wget gzip glibc openssl procps tar libgcc libgomp libstdc++ acl && \
    # Update all packages to resolve reported CVEs
    dnf upgrade -y --allowerasing && \
    dnf clean all && \
    rm -rf /var/cache/dnf /var/tmp/*
 
# Copy assembled Bitnami structure from builder
COPY --from=redisbuilder /root/output /
 
# Copy utilities built from source in Stage 1
COPY --from=builder /root/build/wait-for-port/wait-for-port /opt/bitnami/common/bin/wait-for-port
COPY --from=builder /root/build/gosu/gosu /opt/bitnami/common/bin/gosu

# Copy ONLY the compiled .so module files (not entire modules directory with source/deps)
COPY --from=redisbuilder /root/modules-output/*.so /opt/bitnami/redis/modules/

# Configure Redis to automatically load modules in default config
RUN echo "" >> /opt/bitnami/redis/etc/redis-default.conf && \
    echo "# Load Redis modules automatically" >> /opt/bitnami/redis/etc/redis-default.conf && \
    echo "loadmodule /opt/bitnami/redis/modules/redisbloom.so" >> /opt/bitnami/redis/etc/redis-default.conf && \
    echo "loadmodule /opt/bitnami/redis/modules/redisearch.so" >> /opt/bitnami/redis/etc/redis-default.conf && \
    echo "loadmodule /opt/bitnami/redis/modules/rejson.so" >> /opt/bitnami/redis/etc/redis-default.conf && \
    echo "loadmodule /opt/bitnami/redis/modules/redistimeseries.so" >> /opt/bitnami/redis/etc/redis-default.conf
 
# Permission and PATH configuration
RUN chmod +x /opt/bitnami/common/bin/gosu /opt/bitnami/common/bin/wait-for-port && \
    chmod g+rwX /opt/bitnami
ENV PATH="/opt/bitnami/common/bin:/opt/bitnami/redis/bin:$PATH"
 
# Initialization scripts
RUN /opt/bitnami/scripts/redis-cluster/postunpack.sh && \
    ln -sf /opt/bitnami/scripts/redis-cluster/entrypoint.sh /entrypoint.sh && \
    ln -sf /opt/bitnami/scripts/redis-cluster/run.sh /run.sh
 
EXPOSE 6379
 
USER 1001
ENTRYPOINT [ "/opt/bitnami/scripts/redis-cluster/entrypoint.sh" ]
CMD [ "/opt/bitnami/scripts/redis-cluster/run.sh" ]
