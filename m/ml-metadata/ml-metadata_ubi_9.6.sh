#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : ml-metadata
# Version       : master
# Source repo   : https://github.com/google/ml-metadata.git
# Tested on     : UBI:9.6
# Language      : C++
# Ci-Check  : True
# Script License: Apache License, Version 2.0
# Maintainer    : Pankhudi Jain <Pankhudi.Jain@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
# Commit ID for master is: d3a70e909463a231d367270c9f3ef89cf39a1df4

set -ex

PACKAGE_URL=https://github.com/google/ml-metadata.git
PACKAGE_NAME=ml-metadata
PACKAGE_VERSION=${1:-master}
PACKAGE_DIR=ml-metadata

wdir=`pwd`
SCRIPT=$(readlink -f $0)
SCRIPT_DIR=$(dirname $SCRIPT)

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
cd $wdir

export GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=1
python3.11 -m pip install --upgrade pip
python3.11 -m pip install numpy pytest build

#ensure bare 'python' resolves to python3.11
if ! command -v python &>/dev/null; then
    ln -sf /usr/bin/python3.11 /usr/local/bin/python
fi

git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

#remove j2objc reference that causes fetch failure
sed -i '/j2objc/d' WORKSPACE

wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/m/ml-metadata/ml_metadata_ubi9.6.patch
git apply ml_metadata_ubi9.6.patch --reject || true

#update zetasql hash and strip_prefix to match actual archive
sed -i 's/651a768cd51627f58aa6de7039aba9ddab22f4b0450521169800555269447840/86f81591ab5ec20457a5394eb2c5c981e6f6c89f4c49c211d096c3acffec1eb1/g' WORKSPACE
sed -i 's/strip_prefix = "zetasql-/strip_prefix = "googlesql-/g' WORKSPACE

#set correct PYTHON_LIB_PATH 
export PYTHON_BIN_PATH=$(which python3.11)
export PYTHON_LIB_PATH=$(python3.11 -c "import sysconfig; print(sysconfig.get_path('stdlib'))")
export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=python
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:/opt/rh/gcc-toolset-13/root/usr/lib:/usr/lib64:/usr/lib

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
     exit 2;
fi

if ! python3.11 -m build --wheel --no-isolation --outdir="$wdir/"; then
        echo "============ Wheel Creation Failed for Python $PYTHON_VERSION (without isolation) ================="
        echo "Attempting to build with isolation..."

        # Attempt to build the wheel without isolation
        if ! python3.11 -m build --wheel --outdir="$wdir/"; then
            echo "============ Wheel Creation Failed for Python $PYTHON_VERSION ================="
        fi
fi

if ! pytest -vv; then
     echo "------------------$PACKAGE_NAME:Test_fails-------------------------------------"
     echo "$PACKAGE_URL $PACKAGE_NAME"
     echo "$PACKAGE_NAME  |  $PACKAGE_URL  | $PACKAGE_VERSION | GitHub | Fail |  Build_success_but_test_Fails"
     exit 1;
else
     echo "------------------$PACKAGE_NAME:Build_and_test_both_success-------------------------------------"
     echo "$PACKAGE_URL $PACKAGE_NAME"
     echo "$PACKAGE_NAME  |  $PACKAGE_URL  | $PACKAGE_VERSION | GitHub | Pass |  Both_Build_and_Test_Success"
     exit 0;
fi