#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : azure-mgmt-containerregistry
# Version       : 2.0.0
# Source repo   : https://github.com/Azure/azure-sdk-for-python.git
# Tested on		: UBI 8.5
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Saurabh Gore <Saurabh.Gore@ibm.com> 
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=azure-sdk-for-python
PACKAGE_VERSION="${1:-azure-mgmt-containerregistry_2.0.0}"
PACKAGE_URL=https://github.com/Azure/azure-sdk-for-python.git

#To install the dependencies.
yum install -y git  python3 python3-devel make gcc-c++ rust-toolset openssl openssl-devel libffi libffi-devel 
 
#clone the repo.
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

python3 -m pip install pytest pytest-cov setuptools-rust 
python3 -m pip install azure-storage==0.36.0
python3 scripts/dev_setup.py

cd azure-mgmt-containerregistry

# To Build Package
python3 setup.py install

# To test
if ! pytest ; then   
	echo "------------------Build Success but test fails---------------------"
else
	echo "------------------Build and test success-------------------------"
fi
