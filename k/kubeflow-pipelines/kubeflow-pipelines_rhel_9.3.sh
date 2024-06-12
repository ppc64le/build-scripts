#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pipelines
# Version       : master
# Source repo   : https://github.com/kubeflow/pipelines
# Tested on     : Red Hat Enterprise Linux 9.3
# Language      : GO, Python
# Travis-Check  : False
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

PACKAGE_VERSION=${1:-master}
PACKAGE_NAME=pipelines
PACKAGE_URL=https://github.com/kubeflow/pipelines
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

echo "Building kubeflow pipelines persistenceagent image"
docker build --rm -t kfp-persistenceagent-ppc64le:$PACKAGE_VERSION -f backend/Dockerfile.persistenceagent .

echo "Building kubeflow pipelines scheduledworkflow image"
docker build --rm -t kfp-scheduledworkflow-ppc64le:$PACKAGE_VERSION -f backend/Dockerfile.scheduledworkflow .

echo "Building kubeflow pipelines viewercontroller image"
docker build --rm -t kfp-viewercontroller-ppc64le:$PACKAGE_VERSION -f backend/Dockerfile.viewercontroller .

echo "Building kubeflow pipelines cacheserver image"
docker build --rm -t kfp-cacheserver-ppc64le:$PACKAGE_VERSION -f backend/Dockerfile.cacheserver .

echo "Building kubeflow pipelines metadata_writer image"
git apply $SCRIPT_PATH/kfp_metadata_writer_$PACKAGE_VERSION.patch && docker build --rm -t kfp-metadata_writer-ppc64le:$PACKAGE_VERSION -f backend/metadata_writer/Dockerfile .

echo "Building kubeflow pipelines frontend image"
git apply $SCRIPT_PATH/kfp_frontend_$PACKAGE_VERSION.patch && docker build --rm -t kfp-frontend-ppc64le:$PACKAGE_VERSION -f frontend/Dockerfile .
