#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : array_record
# Version          : 0.7.1
# Source repo      : https://github.com/iindyk/array_record
# Tested on        : UBI:9.3
# Language         : Python
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Ramnath Nayak <Ramnath.Nayak@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#                    This repository contains two directories: array_record and array_record_iindyk
#                    ->The array_record directory contains the original build script and source files for the official array_record package.
#                    ->The array_record_iindyk directory exists to facilitate maintenance of patch versions that are released on PyPI under this forked repository. This was necessary to support specific use cases or bug fixes not yet available in the mainline package.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=array_record
PACKAGE_VERSION=${1:-0.7.1}
PACKAGE_URL=https://github.com/iindyk/array_record
PACKAGE_DIR=array_record
BAZEL_VERSION=6.5.0

CURRENT_DIR=${PWD}

yum install -y git make cmake zip tar wget python3.12 python3.12-devel python3.12-pip python3-devel java-11-openjdk java-11-openjdk-devel java-11-openjdk-headless gcc-toolset-13 gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc zlib-devel libjpeg-devel openssl openssl-devel freetype-devel pkgconfig rsync

export GCC_TOOLSET_PATH=/opt/rh/gcc-toolset-13/root/usr
export PATH=$GCC_TOOLSET_PATH/bin:$PATH

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export PATH=$PATH:$JAVA_HOME/bin

#Install bazel
mkdir bazel
cd bazel
wget https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-dist.zip
unzip bazel-${BAZEL_VERSION}-dist.zip
env EXTRA_BAZEL_ARGS="--tool_java_runtime_version=local_jdk" bash ./compile.sh
cp output/bazel /usr/local/bin
export PATH=/usr/local/bin:$PATH
cd $CURRENT_DIR

python3.12 -m pip cache purge
python3.12 -m pip install setuptools wheel etils typing_extensions importlib_resources

declare -A version_commit_mapping=(
    ["0.7.1"]="739630d43ffef522f55380066192dc9fbb14bcc5"
)

commit_id=${version_commit_mapping[$PACKAGE_VERSION]}

cd $CURRENT_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $commit_id

wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/a/array_record_iindyk/array_record_iindyk_0.7.1_1.patch
git apply array_record_iindyk_0.7.1_1.patch

python3 -m pip install setuptools wheel etils typing_extensions importlib_resources

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

