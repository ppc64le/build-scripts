#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package          : protobuf
# Version          : v6.31.0
# Source repo      : https://github.com/protocolbuffers/protobuf
# Tested on   	   : UBI:9.3
# Language         : Python
# Ci-Check     : True
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
    python3.12 python3.12-devel python3.12-pip \
    java-21-openjdk-devel

source /opt/rh/gcc-toolset-13/enable
echo "------------ Bazel Installing --------------"
cd $WORK_DIR
wget https://github.com/bazelbuild/bazel/releases/download/7.1.2/bazel-7.1.2-dist.zip
unzip bazel-7.1.2-dist.zip -d bazel-7.1.2-dist
cd bazel-7.1.2-dist

export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
export PATH=$JAVA_HOME/bin:$PATH
export PYTHON_VERSION=3.12
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
    --copt="-I/usr/include/python${PYTHON_VERSION}"
    
echo "------------Protobuf Built Successfully--------------"
WHEEL_DIR="bazel-bin/python/dist"
WHEEL_PATH=$(find "$WHEEL_DIR" -type f -name "*.whl" | head -n 1)

cp "$WHEEL_PATH" $WORK_DIR
# wheel install
python3.12 -m pip install $WHEEL_PATH
python3.12 -c "import google.protobuf; print(google.protobuf.__version__)"

#bazel test

if !(bazel test //python/... \
  --define=use_fast_cpp_protos=true \
  --test_env=KOKORO_PYTHON_VERSION=3.12 \
  --enable_bzlmod \
  --copt="-I/usr/include/python${PYTHON_VERSION}" \
  --host_copt="-I/usr/include/python${PYTHON_VERSION}"); then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
fi
exit 0

