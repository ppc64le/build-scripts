#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : rules_python
# Version       : 0.31.0
# Source repo   : https://github.com/bazelbuild/rules_python
# Tested on     : UBI:9.3
# Language      : Starlark,Python
# Ci-Check  : True
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
PACKAGE_NAME=rules_python
PACKAGE_VERSION=${1:-0.31.0}
PACKAGE_URL=https://github.com/bazelbuild/rules_python

yum install -y g++ wget git gcc gcc-c++ python3.11 python3.11-devel python3.11-pip zip patch java-11-openjdk java-11-openjdk-devel \
	redhat-rpm-config gcc libffi-devel openssl-devel cargo pkg-config diffutils libxcrypt-compat

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

#Install rust
curl https://sh.rustup.rs -sSf | sh -s -- -y
PATH="$HOME/.cargo/bin:$PATH"
source $HOME/.cargo/env
rustc --version

#Install Cryptography
python3 -m pip install cryptography --no-binary cryptography


git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Apply patch
wget https://raw.githubusercontent.com/ramnathnayak/build-scripts/rules_python/r/rules_python/rules_python_0.31.0.patch
patch -p1 < rules_python_0.31.0.patch


if ! bazel build //...; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! bazel test --test_timeout=600 //...; then
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
