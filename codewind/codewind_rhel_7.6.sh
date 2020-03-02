# ----------------------------------------------------------------------------
#
# Package	: eclipse/codewind
# Version	: latest (0.9.0)
# Source repo	: https://github.com/eclipse/codewind
# Tested on	: rhel_7.6
# Script License: Eclipse Public License - v 2.0
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
# NodeJs version 10.x or later
# Docker is installed and running
# ----------------------------------------------------------------------------

export CODEWIND_VERSION=""

git clone https://github.com/eclipse/codewind.git
cd codewind

if [ "$CODEWIND_VERSION" == "" ]
then
   echo "No specific version specified. Using latest ..."
else
   echo "Building the specified version $CODEWIND_VERSION"
   git checkout ${CODEWIND_VERSION}
fi

wrkdir=`pwd`

# Build appsody binary from source code on Power
cd $wrkdir
./script/build.sh

echo "Build completed !!"