#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : srsly
# Version          : release-v2.5.3
# Source repo      : https://github.com/explosion/srsly
# Tested on        : UBI:9.6
# Language         : Python
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

PACKAGE_NAME=srsly
PACKAGE_URL=https://github.com/explosion/srsly
PACKAGE_VERSION=${1:-release-v2.5.3}
PACKAGE_DIR=srsly

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
python3 -m pip install --no-cache-dir cython setuptools

echo "building srsly..."

if ! python3 -m pip install --no-cache-dir .; then
    echo "------------------$PACKAGE_NAME: build_fail------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Build_Fail"
    exit 1
else
    echo "------------------$PACKAGE_NAME:build_success-----------------"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Build_Success"
fi

cd /

# functional test
if ! (python3 - <<EOF
import srsly
import json

print("srsly version:", srsly.__version__)

# Test JSON serialization/deserialization
data = {
    "name": "OpenShift",
    "version": 4.18,
    "features": ["AI", "ML", "Containers"]
}

json_str = srsly.json_dumps(data)
loaded = srsly.json_loads(json_str)

assert loaded == data, "JSON roundtrip failed"

# Test msgpack serialization/deserialization
msg = srsly.msgpack_dumps(data)
loaded_msg = srsly.msgpack_loads(msg)

assert loaded_msg == data, "Msgpack roundtrip failed"

print("Functional test passed")
EOF
); then
    echo "------------------$PACKAGE_NAME: functional_test_fail------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Functional_Test_Fail"
    exit 2
else
    echo "------------------$PACKAGE_NAME:functional_test_success-----------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Functional_Test_Success"
fi
