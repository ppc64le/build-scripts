# ----------------------------------------------------------------------------
#
# Package	: eclipse/che-devfile-registry
# Version	: 7.8.0
# Source repo	: https://github.com/eclipse/che-devfile-registry
# Tested on	: rhel_7.6
# Script License: Apache License, Version 2.0
# Maintainer	: Vrushali Inamdar <vrushali.inamdar@ibm.com>
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
# Docker version 17.05 or higher is required
# ----------------------------------------------------------------------------

export CHE_DEVFILES_REGISTRY_VERSION=""

git clone https://github.com/eclipse/che-devfile-registry.git
cd che-devfile-registry

if [ "$CHE_DEVFILES_REGISTRY_VERSION" == "" ]
then
   echo "No specific version specified. Using latest ..."
else
   echo "Building the specified version $CHE_DEVFILES_REGISTRY_VERSION"
   git checkout ${CHE_DEVFILES_REGISTRY_VERSION}
fi

wrkdir=`pwd`

# Build registry using UBI images instead of default from source code on Power
cd $wrkdir
./build.sh --rhel

