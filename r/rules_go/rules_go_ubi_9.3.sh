#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : rules_go
# Version          : v0.48.0
# Source repo      : https://github.com/bazelbuild/rules_go
# Tested on        : UBI:9.3
# Language         : Go,Starlark
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

PACKAGE_NAME=rules_go
PACKAGE_VERSION=${1:-v0.48.0}
PACKAGE_URL=https://github.com/bazelbuild/rules_go

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

yum install -y git make wget gcc-c++ java-11-openjdk java-11-openjdk-devel java-11-openjdk-headless gcc python3 zip diffutils protobuf-c

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export PATH=$PATH:$JAVA_HOME/bin

#Install bazel
wget https://github.com/bazelbuild/bazel/releases/download/6.4.0/bazel-6.4.0-dist.zip
mkdir -p  bazel-6.4.0
unzip bazel-6.4.0-dist.zip -d bazel-6.4.0/
cd bazel-6.4.0/
env EXTRA_BAZEL_ARGS="--tool_java_runtime_version=local_jdk" bash ./compile.sh
export PATH=$PATH:`pwd`/output
cd ..

#install go
wget https://go.dev/dl/go1.22.1.linux-ppc64le.tar.gz
tar -C  /usr/local -xf go1.22.1.linux-ppc64le.tar.gz
export GOROOT=/usr/local/go
export GOPATH=$HOME
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

if ! bazel build //go:go ; then
       echo "------------------$PACKAGE_NAME:Build_fails---------------------"
       echo "$PACKAGE_VERSION $PACKAGE_NAME"
       echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
       exit 1
fi

sed -i '33d;65d' go/private/platforms.bzl

if !  bazel test //go/... ; then
      echo "------------------$PACKAGE_NAME::Install_and_Test_fails-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Fails"
      exit 2
else
      echo "------------------$PACKAGE_NAME::Build_and_Test_success-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
      exit 0
fi
