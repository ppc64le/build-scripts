#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : ml_dtypes
# Version          : v0.6.0
# Source repo      : https://github.com/jax-ml/ml_dtypes
# Tested on        : UBI:9.6
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vinit Janbandhu <Vinit.Janbandhu@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=ml_dtypes
PACKAGE_VERSION=${1:-v0.6.0}
PACKAGE_URL=https://github.com/jax-ml/ml_dtypes
PACKAGE_DIR=ml_dtypes
CURRENT_DIR=$(pwd)

# 0.6.0 needs Python >= 3.10 and builds with scikit-build-core + CMake
yum install -y python3.12 python3.12-devel python3.12-pip git cmake make wget gcc-toolset-13 gcc-toolset-13-gcc gcc-toolset-13-gcc-c++

source /opt/rh/gcc-toolset-13/enable
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export CC=/opt/rh/gcc-toolset-13/root/usr/bin/gcc
export CXX=/opt/rh/gcc-toolset-13/root/usr/bin/g++

python3.12 -m pip install --upgrade pip setuptools wheel build ninja scikit-build-core pytest absl-py "numpy>=2.0"

# Clone source with the Eigen submodule
git clone $PACKAGE_URL $PACKAGE_DIR
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION
git submodule update --init --recursive

# Build the wheel (numpy is preinstalled, so no isolation)
if ! python3.12 -m build --wheel --no-isolation ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi
cp dist/*.whl "$CURRENT_DIR/"

# Install the wheel so tests import it, not the source tree
python3.12 -m pip install dist/ml_dtypes*.whl

# Run tests
if ! pytest ml_dtypes/tests ; then
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
