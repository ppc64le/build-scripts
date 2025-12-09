#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : cloud-on-k8s
# Version       : v2.9.0
# Source repo   : https://github.com/elastic/cloud-on-k8s
# Tested on     : Red Hat Enterprise Linux 9.3
# Language      : GO
# Ci-Check  : False
# Script License: Apache License, Version 2.0
# Maintainer    : Sunidhi Gaonkar<Sunidhi.Gaonkar@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#Note: These packages do not need to execute any test cases.

PACKAGE_VERSION=${1:-v2.9.0}
PACKAGE_NAME=cloud-on-k8s
PACKAGE_URL=https://github.com/elastic/cloud-on-k8s
SCRIPT_PATH=$(dirname $(realpath $0))

# Install docker if not found
if ! [ $(command -v docker) ]; then
        sudo yum install -y docker
fi

# Install git if not found
if ! [ $(command -v git) ]; then
        sudo yum install -y git
fi

#Removing existing repository
if [ -d $PACKAGE_NAME ]; then
	echo "Removing existing $PACKAGE_NAME ..."
	rm -rf $PACKAGE_NAME
fi

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Build
cd build && echo "fake empty license" > license.key && cd ..
docker build -t eck-operator --build-arg LICENSE_PUBKEY=license.key -f build/Dockerfile .
