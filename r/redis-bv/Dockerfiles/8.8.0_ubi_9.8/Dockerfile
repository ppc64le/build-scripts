# syntax=docker/dockerfile:1
# Copyright Broadcom, Inc. All Rights Reserved.
# SPDX-License-Identifier: APACHE-2.0

# Stage 1: Build utilities from source using secure Go version (resolves stdlib CVEs)
FROM registry.access.redhat.com/ubi9/ubi:9.8 AS setupbuilder

ARG PACKAGE_VERSION=8.8.0
ARG BITNAMI_COMMIT=731e897
ARG GO_VERSION=1.26.5

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

# Assemble prebuildfs from Bitnami containers repo (commit 731e897 = 8.8.0-debian-12-r3)
RUN git clone https://github.com/bitnami/containers /build/containers && \
    cd /build/containers && \
    git checkout ${BITNAMI_COMMIT}

RUN cd /build/containers/bitnami/redis/8.8/debian-12 && \
    wget https://downloads.bitnami.com/files/stacksmith/redis-${PACKAGE_VERSION}-0-linux-amd64-debian-12.tar.gz && \
    tar -xvf redis-${PACKAGE_VERSION}-0-linux-amd64-debian-12.tar.gz && \
    mkdir -p prebuildfs/opt/bitnami/redis/etc && \
    cp redis-${PACKAGE_VERSION}-linux-amd64-debian-12/files/redis/etc/redis-default.conf \
       prebuildfs/opt/bitnami/redis/etc/

# ----------------------------------------------------------------------------
# Stage 2: Build Redis 8.8.0 with all 4 modules for ppc64le
# ----------------------------------------------------------------------------
FROM registry.access.redhat.com/ubi9/ubi:9.8 AS redisbuilder

WORKDIR /build
ARG PACKAGE_VERSION=8.8.0

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
    llvm-devel \
    lld && \
    yum update -y python3 python3-libs openssh openssh-clients vim-minimal libarchive libcap && \
    yum clean all && \
    rm -rf /var/cache/yum

# Ensure python is available under all expected names
RUN which python3 && python3 --version && \
    mkdir -p /usr/local/bin && \
    ln -sf /usr/bin/python3 /usr/local/bin/python3 && \
    ln -sf /usr/bin/python3 /usr/local/bin/python && \
    ln -sf /usr/bin/python3 /usr/bin/python && \
    which python3 && which python && \
    python3 --version && python --version

# Patch is in the Dockerfile directory (build context) - copy it directly
COPY redis-bv_8.8.0.patch /build/

# Clone Redis 8.8.0 and apply ppc64le patch
RUN cd /build && \
    git clone https://github.com/redis/redis && \
    cd redis && \
    git checkout ${PACKAGE_VERSION} && \
    patch -p1 < /build/redis-bv_${PACKAGE_VERSION}.patch

# Fix modules/Makefile - add ppc64le Rust toolchain case
RUN cd /build/redis && python3 <<'EOF'
content = open('modules/Makefile').read()
old = "\t\t\tfi ;; \\\n\t\t*) echo"
new = "\t\t\tfi ;; \\\n\t\t'ppc64le') \\\n\t\t\tRUST_INSTALLER=\"rust-$${RUST_VERSION}-powerpc64le-unknown-linux-gnu\"; \\\n\t\t\tRUST_SHA256=\"\"; \\\n\t\t\t;; \\\n\t\t*) echo"
assert old in content, "NO MATCH - modules/Makefile"
open('modules/Makefile', 'w').write(content.replace(old, new))
print("OK")
EOF

# Fix modules/common.mk - add ppc64le arch map entry
RUN cd /build/redis && python3 <<'EOF'
content = open('modules/common.mk').read()
old = "ARCH_MAP_aarch64 := arm64v8\nARCH_MAP_arm64 := arm64v8"
new = "ARCH_MAP_aarch64 := arm64v8\nARCH_MAP_arm64 := arm64v8\nARCH_MAP_ppc64le := ppc64le"
assert old in content, "NO MATCH - common.mk"
open('modules/common.mk', 'w').write(content.replace(old, new))
print("OK")
EOF

# First build pass - clones all module sources (redisjson, redistimeseries,
# redisbloom, redisearch). Expected to fail on ppc64le arch guards; that is OK.
RUN cd /build/redis && \
    EXTRA_CFLAGS="" && \
    if [[ $(uname -m) == "ppc64le" ]]; then \
        if grep -iq "POWER10" /proc/cpuinfo || lscpu | grep -iq "POWER10"; then \
            echo "Power10 CPU detected - applying P10 optimisation flags" && \
            EXTRA_CFLAGS="-mcpu=power10 -mtune=power10"; \
        fi \
    fi && \
    export BUILD_WITH_MODULES=yes && \
    export DISABLE_WERRORS=yes && \
    export IGNORE_MISSING_DEPS=1 && \
    unset INSTALL_RUST_TOOLCHAIN && \
    make MALLOC=libc EXTRA_CFLAGS="$EXTRA_CFLAGS" -j "$(nproc)" all IGNORE_MISSING_DEPS=1 || true

# Fix RedisTimeSeries - remove ppc64le architecture restriction
RUN find /build/redis/modules/redistimeseries -name "Makefile" \
        | xargs grep -l "only supports 64-bit\|arm64v8" 2>/dev/null \
        | while read mk; do \
            sed -i '/only supports 64-bit/{ N; d }' "$mk" || true; \
            sed -i '/^ifneq.*ARCH.*arm64v8/,/^endif/d' "$mk" || true; \
          done; true

# Fix RedisBloom - remove ppc64le architecture restriction
RUN find /build/redis/modules/redisbloom -name "Makefile" \
        | xargs grep -l "only supports 64-bit\|arm64v8" 2>/dev/null \
        | while read mk; do \
            sed -i '/only supports 64-bit/{ N; d }' "$mk" || true; \
            sed -i '/^ifneq.*ARCH.*arm64v8/,/^endif/d' "$mk" || true; \
          done; true

# Fix RediSearch - disable SVS (x86-only ScalableVectorSearch) via cmake flag
RUN cd /build/redis && python3 <<'EOF'
import subprocess
result = subprocess.run(
    ['find', 'modules/redisearch/src', '-maxdepth', '1', '-name', 'build.sh'],
    capture_output=True, text=True
)
files = [f.strip() for f in result.stdout.strip().splitlines() if f.strip()]
print(f"Found RediSearch build.sh candidates: {files}")
for path in files:
    content = open(path).read()
    old = 'CMAKE_BASIC_ARGS="$CMAKE_BASIC_ARGS -DSVS_SHARED_LIB=OFF"'
    new = 'CMAKE_BASIC_ARGS="$CMAKE_BASIC_ARGS -DSVS_SHARED_LIB=OFF -DUSE_SVS=OFF"'
    if '-DUSE_SVS=OFF' in content:
        print(f"SKIP - already has -DUSE_SVS=OFF: {path}")
    elif old in content:
        open(path, 'w').write(content.replace(old, new))
        print(f"OK - added -DUSE_SVS=OFF in {path}")
    else:
        print(f"WARN - anchor not found in {path}")
EOF

# Fix RediSearch Rust - RS_FIELDMASK_ALL: u128::MAX -> u64::MAX in ffi/src/lib.rs
RUN cd /build/redis && python3 <<'EOF'
import subprocess
result = subprocess.run(
    ['find', 'modules/redisearch/src', '-path', '*/ffi/src/lib.rs'],
    capture_output=True, text=True
)
files = [f.strip() for f in result.stdout.strip().splitlines() if f.strip()]
print(f"Found ffi/src/lib.rs: {files}")
for path in files:
    content = open(path).read()
    old = "pub const RS_FIELDMASK_ALL: FieldMask = u128::MAX;"
    new = "pub const RS_FIELDMASK_ALL: FieldMask = u64::MAX;"
    if old in content:
        open(path, 'w').write(content.replace(old, new))
        print(f"OK - {path}")
    elif new in content:
        print(f"SKIP - already patched: {path}")
    else:
        print(f"WARN - pattern not found in {path}")
EOF

# Fix RediSearch Rust - blocklist RS_FIELDMASK_ALL in ffi/build.rs
RUN cd /build/redis && python3 <<'EOF'
import subprocess
result = subprocess.run(
    ['find', 'modules/redisearch/src', '-path', '*/ffi/build.rs'],
    capture_output=True, text=True
)
files = [f.strip() for f in result.stdout.strip().splitlines() if f.strip()]
print(f"Found ffi/build.rs: {files}")
for path in files:
    content = open(path).read()
    anchors = [
        ('.blocklist_type("QueryProcessingCtx")',
         '.blocklist_item("RS_FIELDMASK_ALL")\n        .blocklist_type("QueryProcessingCtx")'),
        ('.allowlist_recursively(true)',
         '.allowlist_recursively(true)\n        .blocklist_item("RS_FIELDMASK_ALL")'),
    ]
    patched = False
    for old, new in anchors:
        if '.blocklist_item("RS_FIELDMASK_ALL")' in content:
            print(f"SKIP - already patched: {path}"); patched = True; break
        if old in content:
            open(path, 'w').write(content.replace(old, new, 1))
            print(f"OK - {path}"); patched = True; break
    if not patched:
        print(f"WARN - no anchor found in {path}")
EOF

# Fix RediSearch Rust - u128::read_as_varint -> u64::read_as_varint in fields_only.rs
RUN cd /build/redis && python3 <<'EOF'
import subprocess
result = subprocess.run(
    ['find', 'modules/redisearch/src', '-name', 'fields_only.rs'],
    capture_output=True, text=True
)
files = [f.strip() for f in result.stdout.strip().splitlines() if f.strip()]
print(f"Found fields_only.rs: {files}")
for path in files:
    content = open(path).read()
    old = "let field_mask = u128::read_as_varint(cursor)?;"
    new = "let field_mask = u64::read_as_varint(cursor)?;"
    if old in content:
        open(path, 'w').write(content.replace(old, new))
        print(f"OK - {path}")
    elif new in content:
        print(f"SKIP - already patched: {path}")
    else:
        print(f"WARN - pattern not found in {path}")
EOF

# Fix RediSearch Rust - explicit cast in index_result source files
RUN cd /build/redis && python3 <<'EOF'
import subprocess
result = subprocess.run(
    ['find', 'modules/redisearch/src', '-name', '*.rs', '-path', '*/index_result*'],
    capture_output=True, text=True
)
files = [f.strip() for f in result.stdout.strip().splitlines() if f.strip()]
print(f"Found index_result source files: {files}")
patched = 0
for path in files:
    content = open(path).read()
    if "field_mask: RS_FIELDMASK_ALL," in content:
        count = content.count("field_mask: RS_FIELDMASK_ALL,")
        open(path, 'w').write(
            content.replace("field_mask: RS_FIELDMASK_ALL,",
                            "field_mask: RS_FIELDMASK_ALL as t_fieldMask,")
        )
        print(f"OK - replaced {count} occurrence(s) in {path}")
        patched += count
if patched == 0:
    print("WARN - pattern not found in any index_result source file")
EOF

# Fix VectorSimilarity - guard SVS includes behind #if HAVE_SVS
RUN cd /build/redis && python3 <<'EOF'
import subprocess

# 1. tiered_factory.h
result = subprocess.run(
    ['find', 'modules/redisearch/src', '-path', '*/index_factories/tiered_factory.h'],
    capture_output=True, text=True
)
for path in [f.strip() for f in result.stdout.strip().splitlines() if f.strip()]:
    content = open(path).read()
    old = '#include "VecSim/algorithms/svs/svs_tiered.h"'
    new = '#if HAVE_SVS\n#include "VecSim/algorithms/svs/svs_tiered.h"\n#endif'
    if new in content:
        print(f"SKIP tiered_factory.h")
    elif old in content:
        open(path, 'w').write(content.replace(old, new))
        print(f"OK - tiered_factory.h: {path}")
    else:
        print(f"WARN - svs_tiered.h include not found in {path}")

# 2. svs_factory.cpp - wrap entire file
result = subprocess.run(
    ['find', 'modules/redisearch/src', '-path', '*/index_factories/svs_factory.cpp'],
    capture_output=True, text=True
)
for path in [f.strip() for f in result.stdout.strip().splitlines() if f.strip()]:
    content = open(path).read()
    if '#if HAVE_SVS' in content:
        print(f"SKIP svs_factory.cpp")
        continue
    open(path, 'w').write('#if HAVE_SVS\n' + content + '\n#endif // HAVE_SVS\n')
    print(f"OK - svs_factory.cpp wrapped: {path}")

# 3. vec_sim.cpp - per-line guards
result = subprocess.run(
    ['find', 'modules/redisearch/src', '-path', '*/VecSim/vec_sim.cpp'],
    capture_output=True, text=True
)
for path in [f.strip() for f in result.stdout.strip().splitlines() if f.strip()]:
    lines = open(path).read().splitlines(keepends=True)
    if any('#if HAVE_SVS' in l for l in lines):
        print(f"SKIP vec_sim.cpp")
        continue
    out = []
    i = 0
    p_inc = p_resize = p_shared = False
    while i < len(lines):
        line = lines[i]
        if '#include "VecSim/algorithms/svs/svs_utils.h"' in line and not p_inc:
            out += ['#if HAVE_SVS\n', line, '#endif\n']
            p_inc = True; i += 1; continue
        if 'VecSimSVSThreadPool::resize(' in line and not p_resize:
            out += ['#if HAVE_SVS\n', line, '#endif\n']
            p_resize = True; i += 1; continue
        if 'VecSimSVSThreadPool::getSharedAllocationSize()' in line and not p_shared:
            out += ['#if HAVE_SVS\n', line, '#else\n    return 0;\n#endif\n']
            p_shared = True; i += 1; continue
        out.append(line); i += 1
    open(path, 'w').write(''.join(out))
    summary = [s for s, f in [('svs_utils.h',p_inc),('resize',p_resize),('getSharedAllocationSize',p_shared)] if f]
    print(f"OK - vec_sim.cpp: guarded {', '.join(summary) or 'nothing (WARN)'}")
EOF

# Fix VectorSimilarity - add ppc64le CPU features support in spaces.h
RUN cd /build/redis && python3 <<'EOF'
import subprocess
result = subprocess.run(
    ['find', 'modules/redisearch/src', '-path', '*/spaces/spaces.h'],
    capture_output=True, text=True
)
files = [f.strip() for f in result.stdout.strip().splitlines() if f.strip()]
print(f"Found spaces.h: {files}")
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
patched = False
for path in files:
    try:
        content = open(path).read()
    except OSError:
        continue
    if old in content:
        open(path, 'w').write(content.replace(old, new))
        print(f"OK - {path}"); patched = True; break
if not patched:
    print("WARN - spaces.h pattern not found")
EOF

# Wipe CMake and Rust build caches so all patched sources recompile cleanly
RUN rm -rf /build/redis/modules/redisearch/src/bin/linux-ppc64le-release/ \
           /build/redis/modules/redisearch/src/bin/redisearch_rs/

# Final build pass with all fixes applied
RUN cd /build/redis && \
    EXTRA_CFLAGS="" && \
    if [[ $(uname -m) == "ppc64le" ]]; then \
        if grep -iq "POWER10" /proc/cpuinfo || lscpu | grep -iq "POWER10"; then \
            echo "Power10 CPU detected - applying P10 optimisation flags" && \
            EXTRA_CFLAGS="-mcpu=power10 -mtune=power10"; \
        fi \
    fi && \
    export BUILD_WITH_MODULES=yes && \
    export DISABLE_WERRORS=yes && \
    export IGNORE_MISSING_DEPS=1 && \
    export PATH="/usr/bin:/usr/local/bin:$PATH" && \
    export PYTHON3=/usr/bin/python3 && \
    export PYTHON=/usr/bin/python3 && \
    unset INSTALL_RUST_TOOLCHAIN && \
    which python3 && python3 --version && \
    python3 -c "import sys; print(sys.executable)" && \
    make MALLOC=libc EXTRA_CFLAGS="$EXTRA_CFLAGS" -j "$(nproc)" all IGNORE_MISSING_DEPS=1

# Collect Redis binaries and all 4 module .so files
RUN find /build/redis/modules -maxdepth 2 -name "*.so" | grep -v "deps\|src/bin\|target" && \
    mkdir -p /root/redis/bin /root/redis/modules && \
    find /build/redis/src -maxdepth 1 -type f -executable -name "redis-*" \
        -exec cp {} /root/redis/bin/ \; && \
    cp /build/redis/modules/redisbloom/redisbloom.so           /root/redis/modules/ && \
    cp /build/redis/modules/redisearch/redisearch.so           /root/redis/modules/ && \
    cp /build/redis/modules/redisjson/rejson.so                /root/redis/modules/ && \
    cp /build/redis/modules/redistimeseries/redistimeseries.so /root/redis/modules/ && \
    ls -lh /root/redis/bin/ /root/redis/modules/

# Erase Python RPM packages after build is complete (not needed in final image)
RUN yum clean all && \
    rm -rf /var/cache/yum && \
    rpm -e --nodeps python3 python3-devel python3-libs

# ----------------------------------------------------------------------------
# Stage 3: Final runtime image
# ----------------------------------------------------------------------------
FROM registry.access.redhat.com/ubi9/ubi:9.8

LABEL com.vmware.cp.artifact.flavor="sha256:c50c90cfd9d12b445b011e6ad529f1ad3daea45c26d20b00732fae3cd71f6a83" \
      org.opencontainers.image.documentation="https://github.com/bitnami/containers/tree/main/bitnami/redis/README.md" \
      org.opencontainers.image.source="https://github.com/bitnami/containers/tree/main/bitnami/redis" \
      org.opencontainers.image.title="redis" \
      org.opencontainers.image.version="8.8.0"

ENV HOME="/" \
    OS_ARCH="ppc64le" \
    OS_FLAVOUR="rhel9" \
    OS_NAME="linux"

# Copy Bitnami prebuildfs (scripts, config, directory skeleton)
COPY --from=setupbuilder /build/containers/bitnami/redis/8.8/debian-12/prebuildfs /
COPY --from=setupbuilder /build/containers/bitnami/redis/8.8/debian-12/rootfs /

# Install runtime dependencies and apply all security updates
RUN yum update -y && \
    yum install -y acl ca-certificates curl-minimal gzip glibc openssl procps tar libgcc libgomp libstdc++ && \
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

# Copy utilities built with secure Go (fixes gosu stdlib CVEs)
COPY --from=setupbuilder /build/wait-for-port/wait-for-port /opt/bitnami/common/bin/wait-for-port
COPY --from=setupbuilder /build/gosu/gosu                   /opt/bitnami/common/bin/gosu
COPY --from=redisbuilder /root/redis/bin                    /opt/bitnami/redis/bin
COPY --from=redisbuilder /root/redis/modules                /opt/bitnami/redis/modules

# Create module path expected by Bitnami Helm chart
# (chart uses /opt/bitnami/redis/lib/redis/modules/ in loadmodule directives)
RUN mkdir -p /opt/bitnami/redis/lib/redis/modules && \
    cp /opt/bitnami/redis/modules/*.so /opt/bitnami/redis/lib/redis/modules/ && \
    ls -lh /opt/bitnami/redis/lib/redis/modules/

RUN chmod +x /opt/bitnami/common/bin/gosu /opt/bitnami/common/bin/wait-for-port

ENV APP_VERSION="8.8.0" \
    BITNAMI_APP_NAME="redis" \
    IMAGE_REVISION="0" \
    PATH="/opt/bitnami/common/bin:/opt/bitnami/redis/bin:$PATH"

EXPOSE 6379
USER 1001
ENTRYPOINT [ "/opt/bitnami/scripts/redis/entrypoint.sh" ]
CMD [ "/opt/bitnami/scripts/redis/run.sh" ]
