#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : azure-mgmt-authorization
# Version          : azure-mgmt-authorization_4.0.0
# Source repo      : https://github.com/Azure/azure-sdk-for-python
# Tested on        : UBI:9.3
# Language         : Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vinod.K1 <Vinod.K1@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

PACKAGE_NAME=azure-mgmt-authorization
PACKAGE_VERSION=${1:-azure-mgmt-authorization_4.0.0}
PACKAGE_URL=https://github.com/Azure/azure-sdk-for-python
PACKAGE_DIR=azure-sdk-for-python/sdk/authorization/azure-mgmt-authorization
CURRENT_DIR=$(pwd)

yum install -y git make wget gcc-toolset-13 openssl-devel python3 python3-pip python3-devel

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION

pip install tox setuptools build wheel  pytest-cov setuptools-rust pytest certifi
pip install -r dev_requirements.txt

#install
if ! pip install -e . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:Install_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Install_Success"
    exit 0
fi

# Skiping test part as there is no test-proxy-standalone-linux-ppc64le.tar.gz file  which is not present for ppc64le architecture
