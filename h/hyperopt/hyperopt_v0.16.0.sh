#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : Katib-suggestion-hyperopt
# Version       : v0.16.0
# Source repo   : https://github.com/kubeflow/katib
# Tested on     : Red Hat Enterprise Linux 8.2 (Ootpa)
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
PACKAGE_VERSION=${1:-v0.16.0}
PACKAGE_NAME=katib
PACKAGE_URL=https://github.com/kubeflow/katib.git
SCRIPT_PATH=$(dirname $(realpath $0))

# Install docker if not found
if ! [ $(command -v docker) ]; then
        sudo yum install -y docker
fi

# Install git if not found
if ! [ $(command -v git) ]; then
        sudo yum install -y git
fi

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Steps added to build grpcio from source
git apply $SCRIPT_PATH/hyperopt_${PACKAGE_VERSION}.patch

docker build --rm -t hyperopt-ppc64le:$PACKAGE_VERSION -f cmd/suggestion/hyperopt/v1beta1/Dockerfile .
