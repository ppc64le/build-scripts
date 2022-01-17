# ----------------------------------------------------------------------------
#
# Package       : atlas-intg
# Version       : branch-2.0
# Source repo   : https://github.com/apache/atlas
# Language      : Java
# Travis-Check  : True
# Tested on     : UBI 8.5
# Script License: Apache-2.0 License
# Maintainer    : Priya Seth <sethp@usibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

#Variables
PACKAGE_URL=https://github.com/apache/atlas
PACKAGE_NAME=atlas/intg
PACKAGE_VERSION="${1:-branch-2.0}"
WORKDIR=`pwd`

#Install required dependencies
yum install -y git maven

#Clone the top-level repository
cd $WORKDIR
git clone $PACKAGE_URL
cd atlas
git checkout $PACKAGE_VERSION

#Install build tools
cd build-tools
mvn install

#Build and test atlas intg
cd $WORKDIR/$PACKAGE_NAME
mvn install
