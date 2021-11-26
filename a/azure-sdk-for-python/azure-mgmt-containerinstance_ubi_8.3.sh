# ----------------------------------------------------------------------------
#
# Package       : azure-mgmt-containerinstance
# Version       : 1.4.0
# Source repo   : https://github.com/Azure/azure-sdk-for-python.git
# Tested on     : UBI 8.3
# Script License: Apache License, Version 2 or later
# Maintainer    : Balavva Mirji <Balavva.Mirji@ibm.com>
#
# Disclaimer: This script has beentested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

# Variables
REPO=https://github.com/Azure/azure-sdk-for-python.git
PACKAGE_VERSION=azure-mgmt-containerinstance_1.4.0

echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "PACKAGE_VERSION is an optional paramater whose default value is azure-mgmt-containerinstance_1.4.0"

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

# Install required dependent packages
yum update -y
yum install -y git python38 python38-pip python38-devel make gcc gcc-c++ libffi-devel.ppc64le libffi.ppc64le cargo.ppc64le openssl.ppc64le openssl-devel.ppc64le
ln -s /usr/bin/python3.8 /usr/bin/python

# Clonning repo
git clone $REPO
cd azure-sdk-for-python/
git checkout $PACKAGE_VERSION

python scripts/dev_setup.py
cd azure-mgmt-containerinstance

# Build and test the package
python3 setup.py install
pytest