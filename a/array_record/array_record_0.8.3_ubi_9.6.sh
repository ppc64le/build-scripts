#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : array_record
# Version          : 0.8.3
# Source repo      : https://github.com/google/array_record
# Tested on        : UBI:9.6
# Language         : Python
# Ci-Check  : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Rushikesh Sathe <Rushikesh.Sathe1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# platform using the mentioned version of the package.
# It may not work as expected with newer versions of the
# package and/or distribution. In such a case, please
# contact the "Maintainer" of this script.
# ----------------------------------------------------------------------------

PACKAGE_NAME=array_record
PACKAGE_VERSION=${1:-v0.8.3}
PACKAGE_URL=https://github.com/google/array_record
PACKAGE_DIR=array_record
BAZEL_VERSION=7.2.1

export CURRENT_DIR=${PWD}

yum install -y git make cmake zip tar wget python3.12 python3.12-devel python3.12-pip python3-devel java-21-openjdk-devel java-21-openjdk java-21-openjdk-headless gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc zlib-devel libjpeg-devel openssl openssl-devel freetype-devel pkgconfig rsync

export GCC_TOOLSET_PATH=/opt/rh/gcc-toolset-13/root/usr
export PATH=$GCC_TOOLSET_PATH/bin:$PATH

export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
export PATH=$PATH:$JAVA_HOME/bin

#Install bazel
mkdir bazel
cd bazel
wget https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-dist.zip
unzip bazel-${BAZEL_VERSION}-dist.zip
env EXTRA_BAZEL_ARGS="--tool_java_runtime_version=local_jdk --jobs=4" bash ./compile.sh
cp output/bazel /usr/local/bin
export PATH=/usr/local/bin:$PATH
cd $CURRENT_DIR

python3.12 -m pip cache purge
python3.12 -m pip install setuptools wheel etils typing_extensions importlib_resources

cd $CURRENT_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

wget https://raw.githubusercontent.com/ppc64le/build-scripts/master/a/array_record/array_record_v0.8.3.patch
git apply array_record_v0.8.3.patch

python3 -m pip install setuptools wheel etils typing_extensions importlib_resources absl-py

#Build package
if ! python3.12 -m pip install . ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#Tests are performed in build_whl.sh
if ! sh oss/build_whl.sh ; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi

cp $CURRENT_DIR/array_record/dist/* $CURRENT_DIR
