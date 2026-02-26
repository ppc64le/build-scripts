#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : snowflake-connector-python
# Version          : v4.3.0
# Source repo      : https://github.com/snowflakedb/snowflake-connector-python
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

PACKAGE_NAME=snowflake-connector-python
PACKAGE_URL=https://github.com/snowflakedb/snowflake-connector-python
PACKAGE_VERSION=${1:-v4.3.0}
PACKAGE_DIR=snowflake-connector-python
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

echo "building snowflake-connector-python..."
if ! python${PYTHON_VERSION} -m pip install --no-cache-dir .; then
    echo "------------------$PACKAGE_NAME: build_fail------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Build_Fail"
    exit 1
fi

if ! (python${PYTHON_VERSION} - <<EOF
import snowflake.connector
import cryptography
import OpenSSL
print("All critical dependencies imported successfully")
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
