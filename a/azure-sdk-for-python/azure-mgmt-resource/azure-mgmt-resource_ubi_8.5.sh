#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : azure-mgmt-resource
# Version       : 2.1.0
# Source repo   : https://github.com/Azure/azure-sdk-for-python
# Tested on	: UBI 8.5
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Apurva Agrawal<Apurva.Agrawal3@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=azure-sdk-for-python
PACKAGE_VERSION="${1:-azure-mgmt-resource_2.1.0}"
PACKAGE_URL=https://github.com/Azure/azure-sdk-for-python.git

#install the prerequisite dependency.
yum install -y git  python3 python3-devel make gcc-c++ rust-toolset openssl openssl-devel libffi libffi-devel 

#clone the repo.
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

python3 -m pip install pytest pytest-cov setuptools-rust wheel

# build test-env
cd azure-sdk-tools
python3 setup.py install
cd ..

cd azure-mgmt-resource

# To build
python3 setup.py install

if ! pytest ; then   
	echo "------------------Build Success but test fails---------------------"
else
	echo "------------------Build and test success-------------------------"
fi

