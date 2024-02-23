#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : Katib-suggestion
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
#Note: THese packages do not need to execute any test cases.

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

#Removing existing repository
if [ -d $PACKAGE_NAME ]; then
	echo "Removing existing $PACKAGE_NAME ..."
	rm -rf $PACKAGE_NAME
fi

echo "Cloning $PACKAGE_NAME ..."
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

echo "building katib-suggestion-goptuna image"
docker build --rm -t goptuna-ppc64le:$PACKAGE_VERSION -f cmd/suggestion/goptuna/v1beta1/Dockerfile .

echo "building katib-suggestion-hyperband image"
git apply $SCRIPT_PATH/hyperband_${PACKAGE_VERSION}.patch && docker build --rm -t hyperband-ppc64le:$PACKAGE_VERSION -f cmd/suggestion/hyperband/v1beta1/Dockerfile .

echo "building katib-suggestion-hyperopt image"
git apply $SCRIPT_PATH/hyperopt_${PACKAGE_VERSION}.patch && docker build --rm -t hyperopt-ppc64le:$PACKAGE_VERSION -f cmd/suggestion/hyperopt/v1beta1/Dockerfile .

echo "building katib-suggestion-nas-darts image"
git apply $SCRIPT_PATH/darts_${PACKAGE_VERSION}.patch && docker build --rm -t darts-ppc64le:$PACKAGE_VERSION -f cmd/suggestion/nas/darts/v1beta1/Dockerfile .

echo "building katib-suggestion-pbt image"
git apply $SCRIPT_PATH/pbt_${PACKAGE_VERSION}.patch && docker build --rm -t pbt-ppc64le:$PACKAGE_VERSION -f cmd/suggestion/pbt/v1beta1/Dockerfile .

echo "building katib-suggestion-skopt image"
git apply $SCRIPT_PATH/skopt_${PACKAGE_VERSION}.patch && docker build --rm -t skopt-ppc64le:$PACKAGE_VERSION -f cmd/suggestion/skopt/v1beta1/Dockerfile .
