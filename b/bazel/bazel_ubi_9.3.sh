#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : bazel
# Version          : 7.3.1
# Source repo      : https://github.com/bazelbuild/bazel.git
# Tested on        : UBI:9.3
# Language         : Java
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vipul Ajmera <Vipul.Ajmera@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

#variables
PACKAGE_NAME=bazel
PACKAGE_VERSION=${1:-7.3.1}
PACKAGE_URL=https://github.com/bazelbuild/bazel.git

#install dependencies 
yum install -y git wget gcc gcc-c++ zip unzip python3 python3-devel java-21-openjdk-devel

#installing bootstrap bazel to build bazel
mkdir bazel-dist
cd bazel-dist
wget https://github.com/bazelbuild/bazel/releases/download/${PACKAGE_VERSION}/bazel-${PACKAGE_VERSION}-dist.zip
unzip bazel-${PACKAGE_VERSION}-dist.zip
env EXTRA_BAZEL_ARGS="--tool_java_runtime_version=local_jdk" bash ./compile.sh
cp output/bazel /usr/local/bin
export PATH=/usr/local/bin:$PATH
bazel --version
cd ..

#clone repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#build
if ! bazel build //src:bazel-dev ; then
    echo "------------------$PACKAGE_NAME:build_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:build_success---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Success"
    exit 0
fi

#there is no test file for this package



