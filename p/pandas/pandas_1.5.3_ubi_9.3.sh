#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pandas
# Version       : v1.5.3
# Source repo   : https://github.com/pandas-dev/pandas.git
# Tested on     : UBI:9.3
# Language      : Python, C, Cython, Html
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Abhinav Kumar <Abhinav.Kumar25@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------
PACKAGE_NAME=pandas
PACKAGE_VERSION=${1:-v1.5.3}
PACKAGE_URL=https://github.com/pandas-dev/pandas.git
PACKAGE_DIR=pandas

# Install system dependencies including SQLite and LZMA libraries
yum install -y git gcc gcc-c++ gzip tar make wget xz cmake yum-utils openssl-devel \
    openblas-devel bzip2-devel bzip2 zip unzip libffi-devel zlib-devel autoconf \
    automake libtool cargo pkgconf-pkg-config.ppc64le info.ppc64le fontconfig.ppc64le \
    fontconfig-devel.ppc64le sqlite-devel python-devel python3-pip python3 python3-devel

# Clone the pandas repository and checkout the required version
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

# Initialize and update submodules
git submodule update --init --recursive

# Install dependencies for Pandas and NumPy
pip3 install --upgrade pip
pip3 install "oldest-supported-numpy>=2022.8.16"
pip3 install pytest hypothesis build meson meson-python
pip3 install cython==0.29.32
pip3 install --upgrade --force-reinstall setuptools
pip3 install --upgrade six

PYVER=$(python3 - <<EOF
import sys
print(f"{sys.version_info.major}.{sys.version_info.minor}")
EOF
)

if [[ "$PYVER" == "3.12" ]]; then
    pip3 install numpy==1.26.4
else
    pip3 install numpy==1.23.5
fi

# Attempt to install
if ! (pip3 install .) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Test pandas package
cd ..

if ! (python3 -c "import pandas; print(pandas.__version__)"); then
    echo "------------------pandas:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL pandas"
    echo "pandas  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------pandas:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL pandas"
    echo "pandas  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
fi
