#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : numpy
# Version       : v1.26.4
# Source repo   : https://github.com/numpy/numpy.git
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Bhagyashri Gaikwad <Bhagyashri.Gaikwad2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=numpy
PACKAGE_VERSION=${1:-v1.26.4}
PYTHON_VERSION=${PYTHON_VERSION:-3.11}
PACKAGE_URL=https://github.com/numpy/numpy.git

# Install the specified Python version and development tools
yum install -y python${PYTHON_VERSION} python${PYTHON_VERSION}-devel python${PYTHON_VERSION}-pip git gcc-toolset-13 make 

source /opt/rh/gcc-toolset-13/enable
export LD_PRELOAD=/lib64/libstdc++.so.6
# Install Python build dependencies
python${PYTHON_VERSION} -m pip install --upgrade pip  # Ensure pip is up to date
python${PYTHON_VERSION} -m pip install --ignore-installed "chardet<5" tox Cython pytest hypothesis wheel

if [ -z $PACKAGE_SOURCE_DIR ]; then
    git clone $PACKAGE_URL -b $PACKAGE_VERSION
    cd $PACKAGE_NAME
else
    cd $PACKAGE_SOURCE_DIR
fi

git checkout $PACKAGE_VERSION

# Initialize submodules if necessary
git submodule update --init --recursive

# Check if the version is 1.26.0
if [[ $PACKAGE_VERSION == "v1.26.0" ]]; then
    echo "Building NumPy using setup.py for version $PACKAGE_VERSION"
    # Build using setup.py
    if ! python${PYTHON_VERSION} setup.py install; then
        echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
        exit 1
    fi
else
    # Using pip for versions other than v1.26.0
    if ! python${PYTHON_VERSION} -m pip install . ; then
        echo "------------------$PACKAGE_NAME:install_fails--------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
        exit 1
    fi
fi

# Run tests
if ! python${PYTHON_VERSION} runtests.py; then
    echo "------------------$PACKAGE_NAME:install_success_tests_executed---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Success | Tests_executed"
    exit 0
fi
