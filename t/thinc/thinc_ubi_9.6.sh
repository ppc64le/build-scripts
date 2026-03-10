#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : thinc
# Version          : v8.3.6
# Source repo      : https://github.com/explosion/thinc
# Tested on        : UBI:9.6
# Language         : Python, Cython
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


PACKAGE_NAME=thinc
PACKAGE_URL=https://github.com/explosion/thinc
PACKAGE_VERSION=${1:-release-v8.3.6}
PACKAGE_DIR=thinc

dnf -y install git python3 python3-pip python3-devel make gcc-toolset-13

# Enable GCC toolset
source /opt/rh/gcc-toolset-13/enable
export CC=/opt/rh/gcc-toolset-13/root/usr/bin/gcc
export CXX=/opt/rh/gcc-toolset-13/root/usr/bin/g++

# Clone repository
git clone ${PACKAGE_URL}
cd ${PACKAGE_DIR}
git checkout ${PACKAGE_VERSION}

# Upgrade build tools
python3 -m pip install --upgrade pip setuptools wheel

# Install build dependencies
python3 -m pip install --no-cache-dir cython numpy pydantic blis murmurhash cymem preshed

echo "building thinc...."

if ! python3 -m pip install --no-cache-dir .; then
    echo "------------------$PACKAGE_NAME: build_fail------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Build_Fail"
    exit 1
fi

cd /

# functional test
if ! (python3 - <<EOF
import thinc
from thinc.api import Linear

print("Imported thinc successfully")
print("Version:", thinc.__version__)

model = Linear(nO=2, nI=2)
print("Model created:", model)
EOF
); then
    echo "--------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Both_Install_and_Test_Success"
    exit 0
fi
