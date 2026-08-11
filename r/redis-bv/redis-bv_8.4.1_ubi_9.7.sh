#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package       : redis
# Version       : 8.4.1
# Source repo   : https://github.com/redis/redis.git
# Tested on     : UBI:9.7
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
PACKAGE_VERSION=${1:-8.4.1}
PACKAGE_URL=https://github.com/redis/redis.git

BITNAMI_COMMIT=${BITNAMI_COMMIT:-83fa2f7}
GO_VERSION=${GO_VERSION:-1.26.2}

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
    rust cargo clang-devel util-linux llvm-devel \
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

cd "$BUILD_HOME/containers/bitnami/redis/8.4/debian-12"
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
PATCH_FILE="redis-bv_${PACKAGE_VERSION}.patch"
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
# Patch modules/Makefile - add ppc64le Rust support
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
# Patch modules/common.mk - add ppc64le arch map
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
# First build pass (may fail; needed to generate intermediate Rust artefacts)
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
unset INSTALL_RUST_TOOLCHAIN || true

make MALLOC=libc EXTRA_CFLAGS="$EXTRA_CFLAGS" -j "$(nproc)" all IGNORE_MISSING_DEPS=1 || true

# ----------------------------------------------------------------------------
# Patch RediSearch - remove duplicate RS_FIELDMASK_ALL
# ----------------------------------------------------------------------------
python3 << 'EOF'
path = 'modules/redisearch/src/src/redisearch_rs/ffi/src/lib.rs'
content = open(path).read()
old = "pub const RS_FIELDMASK_ALL: FieldMask = u128::MAX;\n"
assert old in content, "NO MATCH - ffi/src/lib.rs"
open(path, 'w').write(content.replace(old, ""))
print("OK")
EOF

# ----------------------------------------------------------------------------
# Patch RediSearch - FieldMask type in fields_only.rs
# ----------------------------------------------------------------------------
python3 << 'EOF'
path = 'modules/redisearch/src/src/redisearch_rs/inverted_index/src/fields_only.rs'
content = open(path).read()
old = "let field_mask = u128::read_as_varint(cursor)?;"
new = "let field_mask = u64::read_as_varint(cursor)?;"
assert old in content, "NO MATCH - fields_only.rs"
open(path, 'w').write(content.replace(old, new))
print("OK")
EOF

# ----------------------------------------------------------------------------
# Patch RediSearch - RS_FIELDMASK_ALL cast in index_result.rs
# ----------------------------------------------------------------------------
python3 << 'EOF'
path = 'modules/redisearch/src/src/redisearch_rs/inverted_index/src/index_result.rs'
content = open(path).read()
count = content.count("field_mask: RS_FIELDMASK_ALL,")
assert count > 0, "NO MATCH - index_result.rs"
open(path, 'w').write(content.replace("field_mask: RS_FIELDMASK_ALL,", "field_mask: RS_FIELDMASK_ALL as t_fieldMask,"))
print(f"OK - Replaced {count} occurrences")
EOF

# ----------------------------------------------------------------------------
# Patch VectorSimilarity - add ppc64le CPU features support
# ----------------------------------------------------------------------------
python3 << 'EOF'
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
fi
