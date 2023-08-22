#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : rules_rust
# Version          : 0.26.0
# Source repo      : https://github.com/bazelbuild/rules_rust
# Tested on        : UBI 8.7
# Language         : Starlark,Rust
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=rules_rust
PACKAGE_VERSION=${1:-0.26.0}
PACKAGE_URL=https://github.com/bazelbuild/rules_rust

HOME_DIR=${PWD}

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

yum install -y git make wget gcc-c++ java-11-openjdk java-11-openjdk-devel java-11-openjdk-headless gcc python36 zip diffutils protobuf-c patch

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export PATH=$PATH:$JAVA_HOME/bin

#Install bazel
wget https://github.com/bazelbuild/bazel/releases/download/6.2.0/bazel-6.2.0-dist.zip
mkdir -p  bazel-6.2.0
unzip bazel-6.2.0-dist.zip -d bazel-6.2.0/
cd bazel-6.2.0/
export EXTRA_BAZEL_ARGS="--host_javabase=@local_jdk//:jdk" bash
./compile.sh
#export the path of bazel bin
export PATH=$PATH:`pwd`/output
cd ../

cd $HOME_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

#Apply patch
wget https://raw.githubusercontent.com/ppc64le/build-scripts/master/r/rules_rust/rules_rust_0.26.0.patch
patch -p1 < rules_rust_0.26.0.patch

if ! bazel build //... ; then
       echo "------------------$PACKAGE_NAME:Build_fails---------------------"
       echo "$PACKAGE_VERSION $PACKAGE_NAME"
       echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
       exit 1
fi

if !  bazel test //... --sandbox_debug ; then
      echo "------------------$PACKAGE_NAME::Build_and_Test_fails-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Fails"
      exit 2
else
      echo "------------------$PACKAGE_NAME::Build_and_Test_success-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
      exit 0
fi

