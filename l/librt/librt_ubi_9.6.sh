#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : librt
# Version          : v0.8.1
# Source repo      : https://github.com/mypyc/librt
# Tested on        : UBI:9.6
# Language         : Python, C
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Puneet Sharma <Puneet.Sharma21@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=librt
PACKAGE_URL=https://github.com/mypyc/librt
PACKAGE_VERSION=${1:-v0.8.1}
PACKAGE_DIR=librt
PYTHON_VERSION=3.11

dnf -y install \
    git \
    python${PYTHON_VERSION} \
    python${PYTHON_VERSION}-pip \
    python${PYTHON_VERSION}-devel \
    gcc-toolset-13

# Enable GCC toolset
source /opt/rh/gcc-toolset-13/enable
export CXX=/opt/rh/gcc-toolset-13/root/usr/bin/g++

git clone ${PACKAGE_URL}
cd ${PACKAGE_NAME}
git checkout ${PACKAGE_VERSION}

echo "building librt..."
if ! python${PYTHON_VERSION} -m pip install --no-cache-dir .; then
    echo "------------------$PACKAGE_NAME: build_fail------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Build_Fail"
    exit 1
fi

if ! (python${PYTHON_VERSION} - <<EOF
import librt
print("Imported librt successfully")
print("Module:", librt)
print("Package name:", librt.__name__)
EOF
); then
    echo "--------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
