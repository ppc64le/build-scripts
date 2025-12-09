#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : impyla
# Version       : v0.21.0
# Source repo   : https://github.com/cloudera/impyla.git
# Tested on     : UBI:9.3
# Language      : Python
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Aastha Sharma <aastha.sharma4@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -ex

PACKAGE_NAME=impyla
PACKAGE_VERSION=${1:-v0.21.0}
PACKAGE_URL=https://github.com/cloudera/impyla.git
PACKAGE_DIR=impyla

yum install -y wget python3 python3-devel python3-pip git libffi make gcc-toolset-13 krb5-libs krb5-devel krb5-workstation

#export path for gcc-13
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

git clone $PACKAGE_URL $PACKAGE_NAME
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION
pip install pytest sqlalchemy thrift==0.16.0 six bitarray requests 'urllib3<2.0' 'chardet<5.0' pandas

if ! pip install .;  then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Skipping these tests as they fail due to connection error because of local servers needed (impalad on port 21050, hiveserver2 on 10000)
if ! pytest -m "not connect" --deselect impala/tests/test_dbapi_connect.py --deselect impala/tests/test_hive.py --deselect impala/tests/test_hive_dict_cursor.py --deselect impala/tests/test_hs2_fault_injection.py --deselect impala/tests/test_http_connect.py --deselect impala/tests/test_impala.py --deselect impala/tests/test_sqlalchemy.py; then
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
