#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : ml-metadata
# Version       : v1.21.0
# Source repo   : https://github.com/google/ml-metadata.git
# Tested on     : UBI:9.6
# Language      : C++
# Ci-Check  : True
# Script License: Apache License, Version 2.0
# Maintainer    : Prerna Kumbhar <Prerna.Kumbhar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -ex

PACKAGE_URL=https://github.com/google/ml-metadata.git
PACKAGE_NAME=ml-metadata
PACKAGE_VERSION=${1:-v1.21.0}
PACKAGE_DIR=ml-metadata
PYTHON_VERSION=${2:-3.11}

wdir=`pwd`
SCRIPT=$(readlink -f $0)
SCRIPT_DIR=$(dirname $SCRIPT)

#Install the dependencies
#added gcc-toolset-13-binutils, gcc, gcc-c++ to resolve linker issues
yum install -y autoconf cmake wget automake libtool zlib zlib-devel libjpeg libjpeg-devel gcc gcc-c++ gcc-toolset-13 gcc-toolset-13-binutils python3 python3-pip python3-devel git unzip zip patch openssl-devel utf8proc tzdata diffutils libffi-devel
source /opt/rh/gcc-toolset-13/enable

ldconfig /usr/local/lib
export LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib64:${LD_LIBRARY_PATH}

yum install -y java-21-openjdk-devel
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
export PATH=$JAVA_HOME/bin:$PATH

mkdir bazel
cd bazel
wget https://github.com/bazelbuild/bazel/releases/download/7.7.0/bazel-7.7.0-dist.zip
unzip bazel-7.7.0-dist.zip
export BAZEL_DEV_VERSION_OVERRIDE=7.7.0
export EMBED_LABEL=7.7.0
env EXTRA_BAZEL_ARGS="--tool_java_runtime_version=local_jdk" bash ./compile.sh
cp output/bazel /usr/local/bin
export PATH=/usr/local/bin:$PATH
bazel --version
cd $wdir

export GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=1
python${PYTHON_VERSION} -m pip install --upgrade pip
python${PYTHON_VERSION} -m pip install numpy pytest build


git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

sed -i 's|7a35bebd0e1eecbc5bf5bbf5eec03e86686c356802b5540872119bd26f84ecc7|579cb415458e9f3642da0a39a72f79fdfe6dc9c1713b3a823f1e276681b9703e|g' WORKSPACE
sed -i 's|boringssl-16c8d3db1af20fcc04b5190b25242aadcb1fbb30|boringssl-648cbaf033401b7fe7acdce02f275b06a88aab5c|g' WORKSPACE
sed -i 's|16c8d3db1af20fcc04b5190b25242aadcb1fbb30.tar.gz|648cbaf033401b7fe7acdce02f275b06a88aab5c.tar.gz|g' WORKSPACE

#set correct PYTHON_LIB_PATH 
export PYTHON_BIN_PATH=$(which python${PYTHON_VERSION})
export PYTHON_LIB_PATH=$(python${PYTHON_VERSION} -c "import sysconfig; print(sysconfig.get_path('stdlib'))")
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

if ! (python${PYTHON_VERSION} -m pip install .); then 
     echo "------------------$PACKAGE_NAME:Build_fails-------------------------------------"
     echo "$PACKAGE_URL $PACKAGE_NAME"
     echo "$PACKAGE_NAME  |  $PACKAGE_URL  | $PACKAGE_VERSION | GitHub | Fail |  Build_fails"
     return 2;
fi

if ! python${PYTHON_VERSION} -m build --wheel --no-isolation --outdir="$wdir/"; then
        echo "============ Wheel Creation Failed for Python $PYTHON_VERSION (without isolation) ================="
        echo "Attempting to build with isolation..."

        # Attempt to build the wheel without isolation
        if ! python${PYTHON_VERSION} -m build --wheel --outdir="$wdir/"; then
            echo "============ Wheel Creation Failed for Python $PYTHON_VERSION ================="
        fi
fi

if ! pytest -vv; then
     echo "------------------$PACKAGE_NAME:Test_fails-------------------------------------"
     echo "$PACKAGE_URL $PACKAGE_NAME"
     echo "$PACKAGE_NAME  |  $PACKAGE_URL  | $PACKAGE_VERSION | GitHub | Fail |  Build_success_but_test_Fails"
     return 1;
else
     echo "------------------$PACKAGE_NAME:Build_and_test_both_success-------------------------------------"
     echo "$PACKAGE_URL $PACKAGE_NAME"
     echo "$PACKAGE_NAME  |  $PACKAGE_URL  | $PACKAGE_VERSION | GitHub | Pass |  Both_Build_and_Test_Success"
     return 0;
fi
