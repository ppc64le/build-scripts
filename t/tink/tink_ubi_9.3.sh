#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package       : tink
# Version       : v1.7.0
# Source repo   : https://github.com/tink-crypto/tink.git
# Tested on     : UBI 9.3
# Language      : Java, Others
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Pratibh Goshi<pratibh.goshi@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
set -e

PACKAGE_NAME=tink
PACKAGE_VERSION=${1:-v1.7.0}
PACKAGE_URL=https://github.com/tink-crypto/tink.git


# install tools and dependent packages
yum install -y git wget unzip sudo make gcc gcc-c++ zip unzip cmake unzip python3 python3-devel java-21-openjdk-devel
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
export PATH=$JAVA_HOME/bin:$PATH

#installing bootstrap bazel to build bazel
BAZEL_VERSION=${1:-7.3.1}
mkdir bazel-dist
cd bazel-dist
wget https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-dist.zip
unzip bazel-${BAZEL_VERSION}-dist.zip
env EXTRA_BAZEL_ARGS="--tool_java_runtime_version=local_jdk" bash ./compile.sh
cp output/bazel /usr/local/bin
export PATH=/usr/local/bin:$PATH
bazel --version

cd ..

# clone and checkout specified version
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION


#Build
bazel build
if [ $? != 0 ]
then
  echo "Build  failed for $PACKAGE_NAME-$PACKAGE_VERSION"
  exit 1
fi

# There is no test cases
exit 0