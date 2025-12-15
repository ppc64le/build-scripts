#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : bazel
# Version       : 6.3.2
# Source repo   : https://github.com/bazelbuild/bazel
# Tested on     : UBI: 8.7
# Language      : Java
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Stuti Wali <Stuti.Wali@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=bazel
PACKAGE_URL=https://github.com/bazelbuild/bazel

# Default tag bazel
if [ -z "$1" ]; then
  export PACKAGE_VERSION="6.3.2"
else
  export PACKAGE_VERSION="$1"
fi


# install tools and dependent packages
yum install -y wget git zip unzip gcc-c++ gcc make  java-11-openjdk-devel  
export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-11)(?=.*ppc64le)')
export PATH=$JAVA_HOME/bin:$PATH

#installing python
wget https://github.com/indygreg/python-build-standalone/releases/download/20230507/cpython-3.9.16+20230507-ppc64le-unknown-linux-gnu-install_only.tar.gz
tar -xvzf cpython-3.9.16+20230507-ppc64le-unknown-linux-gnu-install_only.tar.gz
export PATH=$(pwd)/python/bin:$PATH
ln -sf /python/bin/python3.9 /usr/bin/python
mkdir bazel
cd bazel

#installing bazel from source
wget https://github.com/bazelbuild/bazel/releases/download/${PACKAGE_VERSION}/bazel-${PACKAGE_VERSION}-dist.zip
unzip bazel-${PACKAGE_VERSION}-dist.zip
env EXTRA_BAZEL_ARGS="--tool_java_runtime_version=local_jdk" bash ./compile.sh
cp output/bazel /usr/local/bin
export PATH=/usr/local/bin:$PATH
bazel --version
cd ..
mv bazel baz

# Cloning the repository 
git clone $PACKAGE_URL 
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#building bazel
if ! bazel build //src:bazel; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 1
else
    echo "------------------$PACKAGE_NAME:install_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 0
fi
