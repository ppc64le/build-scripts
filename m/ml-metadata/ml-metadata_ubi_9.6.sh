#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : ml-metadata
# Version       : master
# Source repo   : https://github.com/google/ml-metadata
# Tested on     : UBI 9.6
# Language      : C++
# Travis-Check  : True
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

PACKAGE_URL=https://github.com/google/ml-metadata
PACKAGE_NAME=ml-metadata
PACKAGE_VERSION=master

wdir=`pwd`
SCRIPT=$(readlink -f $0)
SCRIPT_DIR=$(dirname $SCRIPT)

yum update -y
yum install -y autoconf cmake wget automake libtool zlib zlib-devel libjpeg libjpeg-devel gcc gcc-c++ gcc-gfortran git unzip zip python3.9 python3.9-devel python3.9-pip patch openssl-devel utf8proc tzdata diffutils libffi-devel

yum install -y java-11-openjdk-devel
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export PATH=$JAVA_HOME/bin:$PATH

mkdir bazel
cd bazel
wget https://github.com/bazelbuild/bazel/releases/download/6.1.0/bazel-6.1.0-dist.zip
unzip bazel-6.1.0-dist.zip
env EXTRA_BAZEL_ARGS="--tool_java_runtime_version=local_jdk" bash ./compile.sh
cp output/bazel /usr/local/bin
export PATH=/usr/local/bin:$PATH
cd $wdir

export GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=1
python3.9 -m pip install numpy pytest

git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git apply $SCRIPT_DIR/ml_metadata_ubi9.6.patch

export BAZEL_ARGS="--jobs=2 --local_cpu_resources=2"
export PYTHON_BIN_PATH=$(which python3)

if ! (python3.9 -m pip install .); then 
     echo "------------------$PACKAGE_NAME:Build_fails-------------------------------------"
     echo "$PACKAGE_URL $PACKAGE_NAME"
     echo "$PACKAGE_NAME  |  $PACKAGE_URL  | $PACKAGE_VERSION | GitHub | Fail |  Build_fails"
     exit 2;

elif ! pytest -vv; then
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
