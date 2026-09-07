#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package       : redis
# Version       : 8.8.0
# Source repo   : https://github.com/redis/redis.git
# Tested on     : UBI 9.8
# Language      : c,c++,rust
# Ci-Check      : True
# Script License: Apache License Version 2.0
# Maintainer    : Veenious D Geevarghese <Veenious.Geevarghese@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=redis
SCRIPT_PACKAGE_VERSION=8.8.0
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}
PACKAGE_URL=https://github.com/redis/redis.git

# Bitnami containers repo commit for redis/8.8/debian-12
BITNAMI_COMMIT=${BITNAMI_COMMIT:-731e897}
GO_VERSION=${GO_VERSION:-1.24.3}

BUILD_HOME=$(pwd)
SCRIPT_PATH=$(dirname "$(realpath "$0")")
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

# ----------------------------------------------------------------------------
# Install system dependencies
# ----------------------------------------------------------------------------
yum update -y
yum install -y \
    git wget tar gcc gcc-c++ make \
    autoconf automake libtool diffutils \
    tcl procps-ng libstdc++-devel patch cmake \
    python3 python3-devel openssl-devel \
    rust cargo clang-devel util-linux llvm-devel lld \
    acl ca-certificates curl-minimal gzip glibc \
    libgcc libgomp xz unzip zip findutils which
yum update -y python3 python3-libs openssh openssh-clients vim-minimal libarchive libcap
yum clean all

# Ensure python is available as both 'python3' and 'python'
mkdir -p /usr/local/bin
ln -sf /usr/bin/python3 /usr/local/bin/python3
ln -sf /usr/bin/python3 /usr/local/bin/python
ln -sf /usr/bin/python3 /usr/bin/python
python3 --version

# ----------------------------------------------------------------------------
# Install Go (fixes stdlib CVEs: CVE-2025-68121, CVE-2025-58183, etc.)
# ----------------------------------------------------------------------------
wget -q "https://go.dev/dl/go${GO_VERSION}.linux-ppc64le.tar.gz"
tar -C /usr/local -xzf "go${GO_VERSION}.linux-ppc64le.tar.gz"
rm "go${GO_VERSION}.linux-ppc64le.tar.gz"
export PATH="/usr/local/go/bin:$PATH"
go version

# ----------------------------------------------------------------------------
# Build wait-for-port from source
# ----------------------------------------------------------------------------
git clone https://github.com/bitnami/wait-for-port "$BUILD_HOME/wait-for-port"
cd "$BUILD_HOME/wait-for-port"
git checkout v1.0.10
go build .

# ----------------------------------------------------------------------------
# Build gosu from source (fixes 8 stdlib CVEs in pre-compiled binary)
# ----------------------------------------------------------------------------
git clone https://github.com/tianon/gosu "$BUILD_HOME/gosu"
cd "$BUILD_HOME/gosu"
git checkout 1.19
CGO_ENABLED=0 go build -o gosu .

# ----------------------------------------------------------------------------
# Assemble Bitnami prebuildfs
# ----------------------------------------------------------------------------
git clone https://github.com/bitnami/containers "$BUILD_HOME/containers"
cd "$BUILD_HOME/containers"
git checkout "$BITNAMI_COMMIT"

cd "$BUILD_HOME/containers/bitnami/redis/8.8/debian-12"
wget "https://downloads.bitnami.com/files/stacksmith/redis-${PACKAGE_VERSION}-0-linux-amd64-debian-12.tar.gz"
tar -xvf "redis-${PACKAGE_VERSION}-0-linux-amd64-debian-12.tar.gz"
mkdir -p prebuildfs/opt/bitnami/redis/etc
cp "redis-${PACKAGE_VERSION}-linux-amd64-debian-12/files/redis/etc/redis-default.conf" \
   prebuildfs/opt/bitnami/redis/etc/

# Copy prebuildfs and rootfs into place
cp -r prebuildfs/. /
cp -r rootfs/. /

# ----------------------------------------------------------------------------
# Clone Redis
# ----------------------------------------------------------------------------
cd "$BUILD_HOME"
if ! git clone "$PACKAGE_URL" "$BUILD_HOME/redis"; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Clone_Fails"
    exit 0
fi

cd "$BUILD_HOME/redis"
git checkout "$PACKAGE_VERSION"

# ----------------------------------------------------------------------------
# Apply ppc64le patch
# ----------------------------------------------------------------------------
PATCH_FILE="redis-bv_${SCRIPT_PACKAGE_VERSION}.patch"
if [ -f "$SCRIPT_PATH/$PATCH_FILE" ]; then
    echo "Applying patch $SCRIPT_PATH/$PATCH_FILE"
    if ! git apply "$SCRIPT_PATH/$PATCH_FILE"; then
        echo "------------------$PACKAGE_NAME:patch_fails---------------------------------------"
        exit 1
    fi
else
    echo "Patch file $SCRIPT_PATH/$PATCH_FILE not found"
    exit 1
fi

# ----------------------------------------------------------------------------
# Patch modules/Makefile - add ppc64le Rust toolchain support
#
# The modules/Makefile has a case block that selects the right Rust installer
# tarball URL per architecture. ppc64le is not listed by default. We add it
# so that the Rust toolchain install step succeeds on ppc64le.
# Note: RUST_SHA256 is intentionally left blank; the script skips checksum
#       verification when empty.
# ----------------------------------------------------------------------------
python3 << 'EOF'
content = open('modules/Makefile').read()
old = "\t\t\tfi ;; \\\n\t\t*) echo"
new = (
    "\t\t\tfi ;; \\\n"
    "\t\t'ppc64le') \\\n"
    "\t\t\tRUST_INSTALLER=\"rust-$${RUST_VERSION}-powerpc64le-unknown-linux-gnu\"; \\\n"
    "\t\t\tRUST_SHA256=\"\"; \\\n"
    "\t\t\t;; \\\n"
    "\t\t*) echo"
)
assert old in content, "NO MATCH - modules/Makefile"
open('modules/Makefile', 'w').write(content.replace(old, new))
print("OK")
EOF

# ----------------------------------------------------------------------------
# Patch modules/common.mk - add ppc64le arch map entry
#
# common.mk maps uname -m output to Docker arch tag names.
# Without ppc64le in ARCH_MAP, module builds fail looking up the arch string.
# ----------------------------------------------------------------------------
python3 << 'EOF'
content = open('modules/common.mk').read()
old = "ARCH_MAP_aarch64 := arm64v8\nARCH_MAP_arm64 := arm64v8"
new = "ARCH_MAP_aarch64 := arm64v8\nARCH_MAP_arm64 := arm64v8\nARCH_MAP_ppc64le := ppc64le"
assert old in content, "NO MATCH - common.mk"
open('modules/common.mk', 'w').write(content.replace(old, new))
print("OK")
EOF

# ----------------------------------------------------------------------------
# First build pass (may fail; needed to clone all module sources)
# This pass clones redisjson, redistimeseries, redisbloom, redisearch sources
# via 'get_source'. It will fail because ppc64le arch guards block the build,
# but that is expected - we patch sources afterwards and do a second pass.
# ----------------------------------------------------------------------------
EXTRA_CFLAGS=""
if [[ "$(uname -m)" == "ppc64le" ]]; then
    if grep -iq "POWER10" /proc/cpuinfo || lscpu | grep -iq "POWER10"; then
        echo "Power10 CPU detected - applying P10 optimisation flags"
        EXTRA_CFLAGS="-mcpu=power10 -mtune=power10"
    fi
fi

export BUILD_WITH_MODULES=yes
export DISABLE_WERRORS=yes
export IGNORE_MISSING_DEPS=1
unset INSTALL_RUST_TOOLCHAIN || true

make MALLOC=libc EXTRA_CFLAGS="$EXTRA_CFLAGS" -j "$(nproc)" all IGNORE_MISSING_DEPS=1 || true

# ----------------------------------------------------------------------------
# Patch RedisTimeSeries - remove ppc64le architecture restriction
# (modules/redistimeseries/src is cloned by the first build pass)
# ----------------------------------------------------------------------------
find "$BUILD_HOME/redis/modules/redistimeseries" -name "Makefile" \
    | xargs grep -l "only supports 64-bit\|arm64v8" 2>/dev/null \
    | while read mk; do
        echo "Patching $mk"
        sed -i '/only supports 64-bit/{ N; d }' "$mk" || true
        sed -i '/^ifneq.*ARCH.*arm64v8/,/^endif/d' "$mk" || true
        echo "Done patching $mk"
    done

# ----------------------------------------------------------------------------
# Patch RedisBloom - remove ppc64le architecture restriction
# ----------------------------------------------------------------------------
find "$BUILD_HOME/redis/modules/redisbloom" -name "Makefile" \
    | xargs grep -l "only supports 64-bit\|arm64v8" 2>/dev/null \
    | while read mk; do
        echo "Patching $mk"
        sed -i '/only supports 64-bit/{ N; d }' "$mk" || true
        sed -i '/^ifneq.*ARCH.*arm64v8/,/^endif/d' "$mk" || true
        echo "Done patching $mk"
    done

# ----------------------------------------------------------------------------
# Patch RediSearch - disable SVS (ScalableVectorSearch) on ppc64le
#
# SVS contains x86-only inline assembly. With -DUSE_SVS=OFF cmake sets
# HAVE_SVS=0. Additionally svs_factory.cpp is compiled unconditionally by
# CMakeLists.txt, so it must be wrapped with #if HAVE_SVS at source level.
# ----------------------------------------------------------------------------
python3 << 'EOF'
import subprocess

# In 8.8.0 the Makefile is a thin wrapper - the cmake invocation lives in build.sh
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
        print(f"OK - added -DUSE_SVS=OFF to cmake invocation in {path}")
    else:
        print(f"WARN - anchor not found in {path}")
EOF

# ----------------------------------------------------------------------------
# Patch RediSearch Rust sources for ppc64le
#
# On ppc64le, t_fieldMask = uint64_t. Fixes:
# 1. ffi/src/lib.rs: RS_FIELDMASK_ALL u128::MAX -> u64::MAX
# 2. ffi/build.rs:   blocklist RS_FIELDMASK_ALL to avoid duplicate from bindgen
# 3. fields_only.rs: u128::read_as_varint -> u64::read_as_varint
# 4. index_result:   add explicit "as t_fieldMask" cast
# ----------------------------------------------------------------------------

# Fix 1: Change RS_FIELDMASK_ALL from u128::MAX to u64::MAX in ffi/src/lib.rs
python3 << 'EOF'
import subprocess

result = subprocess.run(
    ['find', 'modules/redisearch/src', '-path', '*/ffi/src/lib.rs'],
    capture_output=True, text=True
)
files = [f.strip() for f in result.stdout.strip().splitlines() if f.strip()]
print(f"Found ffi/src/lib.rs candidates: {files}")

for path in files:
    content = open(path).read()
    old = "pub const RS_FIELDMASK_ALL: FieldMask = u128::MAX;"
    new = "pub const RS_FIELDMASK_ALL: FieldMask = u64::MAX;"
    if old in content:
        open(path, 'w').write(content.replace(old, new))
        print(f"OK - changed RS_FIELDMASK_ALL to u64::MAX in {path}")
    elif new in content:
        print(f"SKIP - already patched: {path}")
    else:
        print(f"WARN - RS_FIELDMASK_ALL u128::MAX pattern not found in {path}")
EOF

# Fix 2: Blocklist RS_FIELDMASK_ALL in ffi/build.rs
python3 << 'EOF'
import subprocess

result = subprocess.run(
    ['find', 'modules/redisearch/src', '-path', '*/ffi/build.rs'],
    capture_output=True, text=True
)
files = [f.strip() for f in result.stdout.strip().splitlines() if f.strip()]
print(f"Found ffi/build.rs candidates: {files}")

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
            print(f"SKIP - already has blocklist_item in {path}")
            patched = True
            break
        if old in content:
            open(path, 'w').write(content.replace(old, new, 1))
            print(f"OK - added blocklist_item(RS_FIELDMASK_ALL) in {path}")
            patched = True
            break
    if not patched:
        print(f"WARN - no suitable anchor found in {path}; RS_FIELDMASK_ALL may be emitted by bindgen")
EOF

# Fix 3: Change u128::read_as_varint -> u64::read_as_varint in fields_only.rs
python3 << 'EOF'
import subprocess

result = subprocess.run(
    ['find', 'modules/redisearch/src', '-name', 'fields_only.rs'],
    capture_output=True, text=True
)
files = [f.strip() for f in result.stdout.strip().splitlines() if f.strip()]
print(f"Found fields_only.rs candidates: {files}")

for path in files:
    content = open(path).read()
    old = "let field_mask = u128::read_as_varint(cursor)?;"
    new = "let field_mask = u64::read_as_varint(cursor)?;"
    if old in content:
        open(path, 'w').write(content.replace(old, new))
        print(f"OK - patched fields_only.rs at {path}")
    elif new in content:
        print(f"SKIP - already patched: {path}")
    else:
        print(f"WARN - u128::read_as_varint not found in {path}")
EOF

# Fix 4: Add explicit cast in index_result source files
python3 << 'EOF'
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
    print("WARN - 'field_mask: RS_FIELDMASK_ALL,' not found in any index_result source file")
EOF

# ----------------------------------------------------------------------------
# Patch VectorSimilarity - guard all SVS includes/code behind HAVE_SVS
#
# With -DUSE_SVS=OFF, HAVE_SVS=0 and SVS submodule headers are absent.
# CMakeLists.txt compiles svs_factory.cpp unconditionally, so we wrap its
# entire content with #if HAVE_SVS. tiered_factory.h and vec_sim.cpp also
# need individual guards for their SVS-specific lines.
# ----------------------------------------------------------------------------
python3 << 'EOF'
import subprocess

# 1. tiered_factory.h - includes svs_tiered.h unconditionally
result = subprocess.run(
    ['find', 'modules/redisearch/src', '-path', '*/index_factories/tiered_factory.h'],
    capture_output=True, text=True
)
for path in [f.strip() for f in result.stdout.strip().splitlines() if f.strip()]:
    content = open(path).read()
    old = '#include "VecSim/algorithms/svs/svs_tiered.h"'
    new = '#if HAVE_SVS\n#include "VecSim/algorithms/svs/svs_tiered.h"\n#endif'
    if new in content:
        print(f"SKIP tiered_factory.h - already patched")
    elif old in content:
        open(path, 'w').write(content.replace(old, new))
        print(f"OK - guarded svs_tiered.h include in {path}")
    else:
        print(f"WARN - svs_tiered.h include not found in {path}")

# 2. svs_factory.cpp - entire file is SVS-only; wrap with #if HAVE_SVS
result = subprocess.run(
    ['find', 'modules/redisearch/src', '-path', '*/index_factories/svs_factory.cpp'],
    capture_output=True, text=True
)
for path in [f.strip() for f in result.stdout.strip().splitlines() if f.strip()]:
    content = open(path).read()
    if '#if HAVE_SVS' in content:
        print(f"SKIP svs_factory.cpp - already patched: {path}")
        continue
    open(path, 'w').write('#if HAVE_SVS\n' + content + '\n#endif // HAVE_SVS\n')
    print(f"OK - wrapped svs_factory.cpp with #if HAVE_SVS in {path}")

# 3. vec_sim.cpp - guard svs_utils.h include and stub SVS-only function bodies
result = subprocess.run(
    ['find', 'modules/redisearch/src', '-path', '*/VecSim/vec_sim.cpp'],
    capture_output=True, text=True
)
for path in [f.strip() for f in result.stdout.strip().splitlines() if f.strip()]:
    lines = open(path).read().splitlines(keepends=True)
    if any('#if HAVE_SVS' in l for l in lines):
        print(f"SKIP vec_sim.cpp - already patched")
        continue

    out = []
    i = 0
    patched_include = False
    patched_resize  = False
    patched_shared  = False

    while i < len(lines):
        line = lines[i]

        if '#include "VecSim/algorithms/svs/svs_utils.h"' in line and not patched_include:
            out.append('#if HAVE_SVS\n')
            out.append(line)
            out.append('#endif\n')
            patched_include = True
            i += 1
            continue

        if 'VecSimSVSThreadPool::resize(' in line and not patched_resize:
            out.append('#if HAVE_SVS\n')
            out.append(line)
            out.append('#endif\n')
            patched_resize = True
            i += 1
            continue

        if 'VecSimSVSThreadPool::getSharedAllocationSize()' in line and not patched_shared:
            out.append('#if HAVE_SVS\n')
            out.append(line)
            out.append('#else\n    return 0;\n#endif\n')
            patched_shared = True
            i += 1
            continue

        out.append(line)
        i += 1

    open(path, 'w').write(''.join(out))
    summary = []
    if patched_include: summary.append('guarded svs_utils.h include')
    if patched_resize:  summary.append('guarded SVS pool resize')
    if patched_shared:  summary.append('stubbed getSharedAllocationSize')
    if summary:
        print(f"OK - {', '.join(summary)} in {path}")
    else:
        print(f"WARN - no SVS patterns found in {path}")
EOF

# ----------------------------------------------------------------------------
# Patch VectorSimilarity - add ppc64le CPU features support
# ----------------------------------------------------------------------------
python3 << 'EOF'
import subprocess

result = subprocess.run(
    ['find', 'modules/redisearch/src', '-path', '*/spaces/spaces.h'],
    capture_output=True, text=True
)
files = [f.strip() for f in result.stdout.strip().splitlines() if f.strip()]
print(f"Found spaces.h candidates: {files}")

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
        print(f"OK - patched {path}")
        patched = True
        break

if not patched:
    print("WARN - spaces.h pattern not found; VectorSimilarity may need manual review")
EOF

# Wipe RediSearch CMake and Rust build caches so all patched sources recompile
echo "Wiping RediSearch CMake and Rust build caches..."
rm -rf modules/redisearch/src/bin/linux-ppc64le-release/
rm -rf modules/redisearch/src/bin/redisearch_rs/
echo "Caches wiped."

# ----------------------------------------------------------------------------
# Final build pass
# ----------------------------------------------------------------------------
export PATH="/usr/bin:/usr/local/bin:$PATH"
export PYTHON3=/usr/bin/python3
export PYTHON=/usr/bin/python3
which python3 && python3 --version

if ! make MALLOC=libc EXTRA_CFLAGS="$EXTRA_CFLAGS" -j "$(nproc)" all IGNORE_MISSING_DEPS=1; then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Build_Fails"
    exit 1
fi

# ----------------------------------------------------------------------------
# Collect Redis binaries and modules
# ----------------------------------------------------------------------------
mkdir -p /root/redis/bin /root/redis/modules

find "$BUILD_HOME/redis/src" -maxdepth 1 -type f -executable -name "redis-*" \
    -exec cp {} /root/redis/bin/ \;

cp "$BUILD_HOME/redis/modules/redisbloom/redisbloom.so"           /root/redis/modules/
cp "$BUILD_HOME/redis/modules/redisearch/redisearch.so"           /root/redis/modules/
cp "$BUILD_HOME/redis/modules/redisjson/rejson.so"                /root/redis/modules/
cp "$BUILD_HOME/redis/modules/redistimeseries/redistimeseries.so" /root/redis/modules/

ls -lh /root/redis/bin/ /root/redis/modules/

# ----------------------------------------------------------------------------
# Install runtime layout under /opt/bitnami
# ----------------------------------------------------------------------------
chmod g+rwX /opt/bitnami
ln -sf /opt/bitnami/scripts/redis/entrypoint.sh /entrypoint.sh
ln -sf /opt/bitnami/scripts/redis/run.sh /run.sh
/opt/bitnami/scripts/redis/postunpack.sh
mkdir -p /opt/bitnami/common/bin
chmod g+rwX /opt/bitnami

cp "$BUILD_HOME/wait-for-port/wait-for-port" /opt/bitnami/common/bin/wait-for-port
cp "$BUILD_HOME/gosu/gosu"                   /opt/bitnami/common/bin/gosu
chmod +x /opt/bitnami/common/bin/gosu /opt/bitnami/common/bin/wait-for-port

cp -r /root/redis/bin/. /opt/bitnami/redis/bin/
cp -r /root/redis/modules/. /opt/bitnami/redis/modules/

# Create symlinks for Bitnami Helm chart compatibility
# (chart expects modules at /opt/bitnami/redis/lib/redis/modules/)
mkdir -p /opt/bitnami/redis/lib/redis/modules
cp /opt/bitnami/redis/modules/*.so /opt/bitnami/redis/lib/redis/modules/
ls -lh /opt/bitnami/redis/lib/redis/modules/

# ----------------------------------------------------------------------------
# Cleanup
# ----------------------------------------------------------------------------
yum clean all
rm -rf /var/cache/yum /var/tmp/*

# ----------------------------------------------------------------------------
# Run tests
# ----------------------------------------------------------------------------
cd "$BUILD_HOME/redis"

cat <<'EOF' > skipfile
*unit/introspection*
EOF

if ! ./runtest --skipfile skipfile; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Both_Install_and_Test_Success"
    exit 0
fi
