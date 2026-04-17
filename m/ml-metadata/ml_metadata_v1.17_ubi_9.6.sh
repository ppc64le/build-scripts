#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : ml-metadata
# Version       : v1.17.0
# Source repo   : https://github.com/google/ml-metadata.git
# Tested on     : UBI:9.6
# Language      : C++
# Ci-Check  : True
# Script License: Apache License, Version 2.0
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

PACKAGE_URL=https://github.com/google/ml-metadata.git
PACKAGE_NAME=ml-metadata
PACKAGE_VERSION=${1:-v1.17.0}
PACKAGE_DIR=ml-metadata

CURRENT_DIR=$(pwd)

#Install the dependencies
#added gcc-toolset-13-binutils, gcc, gcc-c++ to resolve linker issues
yum install -y autoconf cmake wget automake libtool zlib zlib-devel libjpeg libjpeg-devel gcc gcc-c++ gcc-toolset-13 gcc-toolset-13-binutils python3.11 python3.11-pip python3.11-devel git unzip zip patch openssl-devel utf8proc tzdata diffutils libffi-devel
source /opt/rh/gcc-toolset-13/enable

yum install -y java-11-openjdk-devel
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export PATH=$JAVA_HOME/bin:$PATH

mkdir bazel
cd bazel
wget https://github.com/bazelbuild/bazel/releases/download/6.5.0/bazel-6.5.0-dist.zip
unzip bazel-6.5.0-dist.zip
env EXTRA_BAZEL_ARGS="--tool_java_runtime_version=local_jdk" bash ./compile.sh
cp output/bazel /usr/local/bin
export PATH=/usr/local/bin:$PATH
bazel --version
cd $CURRENT_DIR

export GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=1
python3.11 -m pip install --upgrade pip
# Install numpy~=1.22.0 as required by ml-metadata v1.17.0 dependencies
# Using ~= ensures compatibility with 1.22.x versions (1.22.0, 1.22.1, etc.)
python3.11 -m pip install "numpy~=1.22.0" pytest build

#ensure bare 'python' resolves to python3.11
if ! command -v python &>/dev/null; then
    ln -sf /usr/bin/python3.11 /usr/local/bin/python
fi

git clone $PACKAGE_URL
cd $PACKAGE_NAME  # Change directory to the cloned repository
git checkout $PACKAGE_VERSION  # Checkout the specified version

#remove j2objc reference that causes fetch failure
sed -i '/j2objc/d' WORKSPACE

# Download and place the postgresql and zetasql patches in third_party directory
mkdir -p ml_metadata/third_party
wget -O ml_metadata/third_party/postgresql.patch https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/m/ml-metadata/postgresql.patch
wget -O ml_metadata/third_party/zetasql.patch https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/m/ml-metadata/zetasql.patch

# Apply WORKSPACE modifications using sed commands instead of patch file
# Note: Using sed instead of git apply/patch because the WORKSPACE.patch file
# had formatting issues (corrupt at line 49). Sed commands are more reliable
# for simple search-and-replace operations and achieve the same result.
# Add PostgreSQL patch reference
sed -i '/strip_prefix = "postgresql-12.1",/a\    patches = ["//ml_metadata/third_party:postgresql.patch",],' WORKSPACE

# Update Abseil C++
sed -i 's|https://github.com/abseil/abseil-cpp/archive/940c06c25d2953f44310b68eb8aab6114dba11fb.zip|https://github.com/abseil/abseil-cpp/archive/refs/tags/20230125.2.zip|g' WORKSPACE
sed -i 's|abseil-cpp-940c06c25d2953f44310b68eb8aab6114dba11fb|abseil-cpp-20230125.2|g' WORKSPACE
sed -i 's|0e800799aa64d0b4d354f3ff317bbd5fbf42f3a522ab0456bb749fc8d3b67415|2d40102022a01c6f3dddd23ec9ddafff49697a2e4bd09af68bccb74d26ecf64a|g' WORKSPACE

# Update BoringSSL
sed -i 's|1188e29000013ed6517168600fc35a010d58c5d321846d6a6dfee74e4c788b45|579cb415458e9f3642da0a39a72f79fdfe6dc9c1713b3a823f1e276681b9703e|g' WORKSPACE
sed -i 's|boringssl-7f634429a04abc48e2eb041c81c5235816c96514|boringssl-648cbaf033401b7fe7acdce02f275b06a88aab5c|g' WORKSPACE
sed -i 's|7f634429a04abc48e2eb041c81c5235816c96514.tar.gz|648cbaf033401b7fe7acdce02f275b06a88aab5c.tar.gz|g' WORKSPACE

# Update ZetaSQL
sed -i 's|strip_prefix = "zetasql-%s" % ZETASQL_COMMIT,|strip_prefix = "googlesql-%s" % ZETASQL_COMMIT,|g' WORKSPACE
sed -i 's|#patches = \["//ml_metadata/third_party:zetasql.patch"\],|patches = ["//ml_metadata/third_party:zetasql.patch"],|g' WORKSPACE
sed -i "s|sha256 = '651a768cd51627f58aa6de7039aba9ddab22f4b0450521169800555269447840'|sha256 = '86f81591ab5ec20457a5394eb2c5c981e6f6c89f4c49c211d096c3acffec1eb1'|g" WORKSPACE

#set correct PYTHON_LIB_PATH and version
export PYTHON_BIN_PATH=$(which python3.11)
export PYTHON_LIB_PATH=$(python3.11 -c "import sysconfig; print(sysconfig.get_path('stdlib'))")
export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=python
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:/opt/rh/gcc-toolset-13/root/usr/lib:/usr/lib64:/usr/lib
export SETUPTOOLS_SCM_PRETEND_VERSION=1.17.0

#pre-fetch libmysqlclient and patch its cmake invocation to use system
#gcc (/usr/bin/gcc) instead of gcc-toolset-13's cc, which requires
#LIBCTF_1.1 from libctf.so.0 — a version not present on this system.
bazel fetch @libmysqlclient//... 2>/dev/null || true
LIBMYSQL_BUILD=$(find /root/.cache/bazel -name "BUILD.bazel" -path "*/libmysqlclient/*" 2>/dev/null | head -1)
if [ -n "$LIBMYSQL_BUILD" ]; then
    sed -i 's|cmake \.\. -DCMAKE_BUILD_TYPE=Release \${CMAKE_ICONV_FLAG-}|cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_COMPILER=/usr/bin/gcc -DCMAKE_CXX_COMPILER=/usr/bin/g++ ${CMAKE_ICONV_FLAG-}|g' "$LIBMYSQL_BUILD"
    echo "Patched libmysqlclient cmake: $(grep 'cmake \.\.' $LIBMYSQL_BUILD)"
else
    echo "ERROR: Could not find libmysqlclient BUILD.bazel to patch"
    exit 1
fi

#keep only build artifacts clean, preserve fetched repos
bazel clean 2>/dev/null || true

if ! (python3.11 -m pip install .); then 
    echo "------------------$PACKAGE_NAME:Build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL  | $PACKAGE_VERSION | GitHub | Fail |  Build_fails"
    exit 1
fi


if ! pytest -vv; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
