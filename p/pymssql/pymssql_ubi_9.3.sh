#!/bin/bash -e
# ----------------------------------------------------------------------------
# 
# Package       : pymssql
# Version       : v2.2.5
# Source repo   : https://github.com/pymssql/pymssql.git
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
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

# variables
PACKAGE_NAME=pymssql
PACKAGE_VERSION=${1:-v2.2.5}
PACKAGE_URL=https://github.com/pymssql/pymssql.git
CURRENT_DIR=$(pwd)

# Install dependencies and tools.
yum install -y git gcc gcc-c++ python3-devel openssl-devel

#build freetds from source
curl -LO ftp://ftp.freetds.org/pub/freetds/stable/freetds-1.3.17.tar.gz
tar -xzf freetds-1.3.17.tar.gz
cd freetds-1.3.17
./configure --prefix=/usr/local --with-tdsver=7.3
make -j$(nproc)
make install
cd $CURRENT_DIR

export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

# Clone repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Ensure compatible Cython version BEFORE installing requirements
pip install cython==0.29.33 typing-extensions>=4.6.0
#  Now install remaining build tools
pip install setuptools_scm>=5.0 wheel>=0.36.2 pluggy exceptiongroup iniconfig

#  Install requirements WITHOUT upgrading Cython
pip install --no-deps -r dev/requirements-dev.txt

# Install package
if ! ( pip install --no-build-isolation --no-use-pep517 . ); then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Run tests
if ! pytest; then
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
