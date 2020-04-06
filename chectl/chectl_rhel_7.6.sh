# ----------------------------------------------------------------------------
#
# Package	: che-incubator/chectl
# Version	: latest (20200214100619)
# Source repo	: https://github.com/che-incubator/chectl
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
# Node version v10.x or higher is installed and in the path
# ----------------------------------------------------------------------------

export CHECTL_VERSION=""

# install yarn as it is required to build chectl
npm -g install yarn

git clone https://github.com/che-incubator/chectl.git
cd chectl

if [ "$CHECTL_VERSION" == "" ]
then
   echo "No specific version specified. Using latest ..."
else
   echo "Building the specified version $CHECTL_VERSION"
   git checkout ${CHECTL_VERSION}
fi

wrkdir=`pwd`

# Build appsody binary from source code on Power
cd $wrkdir

# Build and test chectl 
yarn
yarn test

CHECTL_BINARY=./bin/run
if [ -f "$CHECTL_BINARY" ]; then    
	./bin/run --help
	echo "* * * Successfully built chectl !"
else 
    echo "Something went wrong while building chectl. Please check console log for more details."
fi
