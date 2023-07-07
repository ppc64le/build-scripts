#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : azure-mgmt-nspkg
# Version       : 3.0.2
# Source repo   : https://github.com/Azure/azure-sdk-for-python
# Tested on	: UBI 8.5
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Apurva Agrawal <Apurva.Agrawal3@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=azure-sdk-for-python
PACKAGE_VERSION="${1:-azure-mgmt-nspkg_3.0.2}"
PACKAGE_URL=https://github.com/Azure/azure-sdk-for-python.git

#install the prerequisite dependency.
yum install -y git  python3 python3-devel make gcc-c++ rust-toolset openssl openssl-devel libffi libffi-devel

#clone the repo.
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

python3 -m pip install pytest pytest-cov setuptools-rust

# build test-env
cd azure-sdk-tools
python3 setup.py install
cd ..

cd azure-mgmt-nspkg

# To build

if ! python3 setup.py install ; then
        echo "------------------Build fails---------------------"
else
        echo "------------------Build success-------------------------"
fi

# No test specified for this package
