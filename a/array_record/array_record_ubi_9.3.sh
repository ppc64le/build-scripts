#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : array_record
# Version       : v0.5.0
# Source repo   : https://github.com/google/array_record
# Tested on     : UBI:9.3
# Language      : Python
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# platform using the mentioned version of the package.
# It may not work as expected with newer versions of the
# package and/or distribution. In such a case, please
# contact the "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

# Variables
PACKAGE_NAME="array_record"
PACKAGE_VERSION=${1:-v0.5.0}
PACKAGE_URL="https://github.com/google/array_record"
WORK_DIR=$(pwd)
PACKAGE_DIR=array_record/build-dir
BAZEL_VERSION=5.4.0
export CURRENT_DIR=${PWD}

echo "Installing dependencies..."

#export PYTHON_BIN="$VENV_DIR/bin/python"
#export PATH="$VENV_DIR/bin:$PATH"


yum install -y git make cmake zip tar wget python3.12 python3.12-devel python3.12-pip python3-devel java-11-openjdk java-11-openjdk-devel java-11-openjdk-headless zlib-devel libjpeg-devel openssl openssl-devel freetype-devel pkgconfig rsync
yum install -y gcc gcc-c++

export CC=/usr/bin/gcc
export CXX=/usr/bin/g++

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export PATH=$JAVA_HOME/bin:/usr/bin:$PATH
export ZLIB_ROOT=/usr
#Installing Bazel
mkdir bazel
cd bazel
wget https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-dist.zip
unzip bazel-${BAZEL_VERSION}-dist.zip
env EXTRA_BAZEL_ARGS="--tool_java_runtime_version=local_jdk --jobs=4" bash ./compile.sh
cp output/bazel /usr/local/bin
export PATH=/usr/local/bin:$PATH
cd $CURRENT_DIR

# Install required Python packages
python3.12 -m pip cache purge
python3.12 -m pip install setuptools wheel etils typing_extensions importlib_resources
ln -s /usr/bin/python3.12 /bin/python


# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#patch apply
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/a/array_record/array_record_v0.5.0.patch
git apply array_record_v0.5.0.patch

# Build the package and create a wheel file

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
    cp $CURRENT_DIR/array_record/dist/* $CURRENT_DIR
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi



