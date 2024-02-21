#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : Katib-suggestion-hyperband
# Version       : v0.16.0
# Source repo   : https://github.com/kubeflow/katib
# Tested on     : Red Hat Enterprise Linux 8.2
# Language      : GO, Python
# Travis-Check  : False
# Script License: Apache License, Version 2.0
# Maintainer    : Pranav Pandit <pranav.pandit1@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#Note- This package does not need any test case execution.

PACKAGE_VERSION=${1:-v0.16.0}
PACKAGE_NAME=katib
PACKAGE_URL=https://github.com/kubeflow/katib.git
PATCH_PATH=$(dirname $(realpath $0))

# Install docker if not found
if ! [ $(command -v docker) ]; then
        sudo yum install -y docker
fi

# Install git if not found
if ! [ $(command -v git) ]; then
        sudo yum install -y git
fi

#Removing existing repo
if [ -d "$PACKAGE_NAME" ]; then
	echo "Removing $PACKAGE_NAME .."
	rm -rf $PACKAGE_NAME
fi

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Steps added to build grpcio from source
git apply $PATCH_PATH/hyperband${PACKAGE_VERSION}.patch

docker build --rm -t hyperband-ppc64le:$PACKAGE_VERSION -f cmd/suggestion/hyperband/v1beta1/Dockerfile .
