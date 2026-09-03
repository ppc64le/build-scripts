#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pandas
# Version       : v3.0.5
# Source repo   : https://github.com/pandas-dev/pandas.git
# Tested on     : UBI:10.2
# Language      : Python, C, Cython, HTML
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Sakshi Jain <sakshi.jain16@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------
PACKAGE_NAME=pandas
PACKAGE_VERSION=${1:-v3.0.5}
PACKAGE_URL=https://github.com/pandas-dev/pandas.git
PACKAGE_DIR=pandas
CURRENT_DIR="${PWD}"
WHEEL_DIR="${CURRENT_DIR}/wheels"

mkdir -p "$WHEEL_DIR"

# Install system dependencies including SQLite and LZMA libraries
yum install -y git gcc gcc-c++ python3.14 python3.14-pip python3.14-devel \
    gzip tar make wget xz cmake yum-utils openssl-devel \
    bzip2-devel bzip2 zip unzip libffi-devel zlib-devel autoconf \
    automake libtool cargo pkgconf-pkg-config.ppc64le info.ppc64le fontconfig.ppc64le \
    fontconfig-devel.ppc64le sqlite-devel

# Clone the pandas repository and checkout the required version
git clone $PACKAGE_URL
cd $PACKAGE_DIR/
git checkout $PACKAGE_VERSION

# Initialize and update submodules
git submodule update --init --recursive

# Install dependencies
python3.14 -m pip install --upgrade pip
python3.14 -m pip install pytest hypothesis build meson meson-python
python3.14 -m pip install cython
python3.14 -m pip install --upgrade --force-reinstall setuptools
python3.14 -m pip install --upgrade six
python3.14 -m pip install meson-python==0.13.1
python3.14 -m pip install patchelf==0.14.5
python3.14 -m pip install meson==1.2.1
python3.14 -m pip install oldest-supported-numpy==2022.8.16
python3.14 -m pip install ninja
python3.14 -m pip install versioneer[toml]
python3.14 -m pip install numpy==2.5.0

# Install pandas package
if ! (python3.14 -m pip install .); then
     echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
     echo "$PACKAGE_URL $PACKAGE_NAME"
     echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | Python $PYTHON_VERSION | GitHub | Fail | Install_Fails"
     exit 1
fi

# Create pandas wheel - same approach as numpy
if ! python3.14 -m build --wheel --no-isolation --outdir="$CURRENT_DIR/"; then
        echo "============ Wheel Creation Failed for Python $PYTHON_VERSION (without isolation) ================="
        echo "Attempting to build with isolation..."

        if ! python3.14 -m build --wheel --outdir="$CURRENT_DIR/"; then
            echo "============ Wheel Creation Failed for Python $PYTHON_VERSION ================="
        fi
fi

cd ..

# Test pandas package
if ! (python3.14 -c "import pandas; print(pandas.__version__)"); then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | Python $PYTHON_VERSION | GitHub | Fail | Install_Success_But_Test_Fails"
    exit 2
else
   echo "------------------$PACKAGE_NAME:Install_and_test_success---------------------------"
   echo "$PACKAGE_URL $PACKAGE_NAME"
   echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | Python $PYTHON_VERSION | GitHub | Pass | Install_and_Test_Success"
   exit 0
fi