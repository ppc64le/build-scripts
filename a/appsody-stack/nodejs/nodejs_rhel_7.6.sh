# ----------------------------------------------------------------------------
#
# Package         : appsody/stacks/incubator/nodejs
# Version         : latest (0.9.0)
# Source repo     : https://github.com/appsody/stacks/tree/master/incubator/nodejs
# Tested on       : rhel_7.6
# Script License  : Apache License, Version 2.0
# Maintainer      : Siddhesh Ghadi <Siddhesh.Ghadi@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

# ----------------------------------------------------------------------------
# Prerequisites:
#
# Docker Version >= 18.06.3-ce is installed and running
#
# Dockerfile-stack and Dockerfile are copied to the current directory of this build script
#
# appsody version 0.5.8 or greater is available in path 
#
# Validation of this stack is dependent on appsody/init-controller image.
# Script assumes init-controller image it built using https://github.com/ppc64le/build-scripts/tree/master/appsody-init-controller
# ----------------------------------------------------------------------------

export APPSODY_STACKS_VERSION=""

wrkdir=`pwd`

# get the source code for stacks repo
git clone https://github.com/appsody/stacks.git
cd stacks

if [ "$APPSODY_STACKS_VERSION" == "" ]
then
   echo "No specific version specified. Using latest ..."
else
   echo "Building the specified version $APPSODY_STACKS_VERSION"
   git checkout ${APPSODY_STACKS_VERSION}
fi

# Build appsody binary from source code on Power
cd $wrkdir
cp -f ./Dockerfile-stack ./stacks/incubator/nodejs/image/Dockerfile-stack
cp -f ./Dockerfile ./stacks/incubator/nodejs/image/project/Dockerfile

cd ./stacks/incubator/nodejs

appsody stack validate 

echo "Appsody stack - nodejs is validated !"
