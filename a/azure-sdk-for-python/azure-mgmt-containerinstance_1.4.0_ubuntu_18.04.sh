#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : azure-mgmt-containerinstance
# Version       : 1.4.0
# Source repo   : https://github.com/Azure/azure-sdk-for-python.git
# Tested on     : Ubuntu 18.04
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Sumit Dubey <sumit.dubey2@ibm.com>
#
# Disclaimer: This script has beentested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

# Variables
PACKAGE_NAME=azure-sdk-for-python
PACKAGE_URL=https://github.com/Azure/azure-sdk-for-python.git
PACKAGE_VERSION="${1:-azure-mgmt-containerinstance_1.4.0}"

# Install required dependent packages
apt-get update -y
apt-get install -y git python3 python3-dev python3-pip python3-distutils python3-markupsafe python3-wrapt build-essential libffi-dev cargo openssl libssl-dev
ln -s /usr/bin/python3 /usr/bin/python

# Cloning repo
cd /opt
if [ ! -d "/opt/azure-sdk-for-python" ]; then
	git clone $PACKAGE_URL
fi
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

python scripts/dev_setup.py
cd azure-mgmt-containerinstance

# Build and test the package
python3 setup.py install
pytest

echo "Build and tests complete."