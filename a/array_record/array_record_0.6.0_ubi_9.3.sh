#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : array_record
# Version       : v0.6.0
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
PACKAGE_VERSION=${1:-v0.6.0}
PACKAGE_URL="https://github.com/google/array_record"
PACKAGE_DIR=array_record
export CURRENT_DIR="${PWD}"
BAZEL_VERSION=7.4.0

# array-record not tagged to use v0.6.0, used hard commit for v0.6.0
PACKAGE_COMMIT="7e299eae0db0d7bfc20f7c1e1548bf86cdbfef5e"

export PYTHON_BIN="$VENV_DIR/bin/python"
export PATH="$VENV_DIR/bin:$PATH"

echo "Installing dependencies..."
# Install system dependencies
yum install -y git make cmake zip tar wget python3.12 python3.12-devel python3.12-pip java-21-openjdk-devel java-21-openjdk java-21-openjdk-headless gcc-toolset-13 gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc zlib-devel libjpeg-devel openssl openssl-devel freetype-devel pkgconfig rsync

export GCC_TOOLSET_PATH=/opt/rh/gcc-toolset-13/root/usr
export PATH=$GCC_TOOLSET_PATH/bin:$PATH

export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
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

echo "Cloning the repository..."
git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_COMMIT
git submodule update --init
echo "Repository cloned and checked out to version $PACKAGE_VERSION."


# Fix Eigen checksum mismatch
EIGEN_ZIP="/tmp/eigen-3.4.0.zip"
wget -q -O "$EIGEN_ZIP" "https://gitlab.com/libeigen/eigen/-/archive/3.4.0/eigen-3.4.0.zip"

# Add MODULE.bazel and BUILD file at the correct path inside the zip
cd /tmp
mkdir -p eigen-3.4.0

cat > /tmp/eigen-3.4.0/MODULE.bazel << 'EIGENMOD'
module(name = "eigen", version = "3.4.0.bcr.2")
EIGENMOD

cat > /tmp/eigen-3.4.0/BUILD << 'EIGENBUILD'
cc_library(
    name = "eigen",
    hdrs = glob(["Eigen/**", "unsupported/Eigen/**"]),
    includes = ["."],
    visibility = ["//visibility:public"],
)
EIGENBUILD

zip "$EIGEN_ZIP" eigen-3.4.0/MODULE.bazel eigen-3.4.0/BUILD
rm -rf /tmp/eigen-3.4.0
cd $CURRENT_DIR/$PACKAGE_NAME

ACTUAL_SHA256_B64=$(openssl dgst -sha256 -binary "$EIGEN_ZIP" | base64 -w 0)
mkdir -p /tmp/bazel_distdir
cp "$EIGEN_ZIP" /tmp/bazel_distdir/

cat >> MODULE.bazel << EOF

archive_override(
    module_name = "eigen",
    urls = ["file:///tmp/eigen-3.4.0.zip"],
    integrity = "sha256-${ACTUAL_SHA256_B64}",
    strip_prefix = "eigen-3.4.0",
)
EOF

# Apply array-record-0.6.0
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/a/array_record/array_record_v0.6.0.patch
git apply array_record_v0.6.0.patch

# Install required Python packages
python3.12 -m pip install --upgrade pip setuptools absl-py etils[epath]
export PYTHON_BIN="$VENV_DIR/bin/python"
export PATH="$VENV_DIR/bin:$PATH"
echo "Building and installing $PACKAGE_NAME..."

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
