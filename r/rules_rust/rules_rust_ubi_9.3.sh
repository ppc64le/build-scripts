#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : rules_rust
# Version       : 0.42.1
# Source repo   : https://github.com/bazelbuild/rules_rust
# Tested on     : UBI:9.3
# Language      : Starlark,Rust
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME=rules_rust
PACKAGE_VERSION=${1:-0.42.1}
PACKAGE_URL=https://github.com/bazelbuild/rules_rust

yum install -y git make wget gcc gcc-c++ java-11-openjdk java-11-openjdk-devel java-11-openjdk-headless gcc python3.11 python3.11-devel python3.11-pip zip diffutils protobuf-c patch \
	automake libyaml-devel perl zlib-devel 

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export PATH=$PATH:$JAVA_HOME/bin
ln -sf /usr/bin/python3.11 /usr/bin/python3

#install bazel
wget https://github.com/bazelbuild/bazel/releases/download/6.4.0/bazel-6.4.0-dist.zip
mkdir -p  bazel-6.4.0
unzip bazel-6.4.0-dist.zip -d bazel-6.4.0/
cd bazel-6.4.0/
env EXTRA_BAZEL_ARGS="--tool_java_runtime_version=local_jdk" bash ./compile.sh
#export the path of bazel bin
export PATH=$PATH:`pwd`/output
cd ../..


git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Apply patch
wget https://raw.githubusercontent.com/ramnathnayak/build-scripts/rules_rust/r/rules_rust/rules_rust_0.42.1.patch
patch -p1 < rules_rust_0.42.1.patch


if ! bazel build //...; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! bazel test //...; then
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

