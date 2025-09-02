#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package          : protobuf
# Version          : v6.31.0
# Source repo      : https://github.com/protocolbuffers/protobuf
# Tested on   	   : UBI:9.3
# Language         : Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Rushikesh Sathe <Rushikesh.Sathe@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -ex


PACKAGE_NAME=protobuf
PACKAGE_VERSION=${1:-v6.31.0}
PACKAGE_URL=https://github.com/protocolbuffers/protobuf
WORK_DIR=$(pwd)
BUILD_DIR="protobuf"


yum install -y git wget gcc-toolset-13 zip unzip \
    python3 python3-devel \
    python3.12 python3.12-devel \
    java-21-openjdk-devel

source /opt/rh/gcc-toolset-13/enable
echo "------------ Bazel Installing --------------"
cd $WORK_DIR
wget https://github.com/bazelbuild/bazel/releases/download/7.1.2/bazel-7.1.2-dist.zip
unzip bazel-7.1.2-dist.zip -d bazel-7.1.2-dist
cd bazel-7.1.2-dist

export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
export PATH=$JAVA_HOME/bin:$PATH

EXTRA_BAZEL_ARGS="--jobs=16 --host_javabase=@local_jdk//:jdk" bash ./compile.sh
chmod +x output/bazel
mv output/bazel /usr/local/bin/bazel

echo "------------Bazel Installed Successfully--------------"
cd $WORK_DIR


git clone $PACKAGE_URL
cd $BUILD_DIR
git checkout $PACKAGE_VERSION

echo "------------Protobuf Cloned at Version $PACKAGE_VERSION--------------"

#apply patch
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/p/protobuf/protobuf_v6.31.0.patch
git apply protobuf_v6.31.0.patch
#build protobuf
bazel clean --expunge

bazel build //python/dist:binary_wheel \
    --//python:python_version=system \
    --//python:limited_api=True \
    --copt="-I/usr/include/python3.12"

WHEEL_DIR="bazel-bin/python/dist"
WHEEL_PATH=$(find "$WHEEL_DIR" -type f -name "*.whl" | head -n 1)

if [[ -f "$WHEEL_PATH" ]]; then
    echo "------------------$PACKAGE_NAME:build_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Build_Success"
    echo "Wheel Output: $WHEEL_PATH"
else
    echo "------------------$PACKAGE_NAME:build_failed-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Failed"
    exit 1
fi

exit 0
