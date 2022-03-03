# -----------------------------------------------------------------------------
#
# Package       : t-digest
# Version       : t-digest-3.0
# Source repo   : https://github.com/tdunning/t-digest.git
# Tested on     : UBI 8.3
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Raju.Sah@ibm.com
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash
set -e

PACKAGE_NAME=t-digest
PACKAGE_VERSION=${1:-t-digest-3.0}
PACKAGE_URL=https://github.com/tdunning/t-digest.git

yum -y install git maven java-1.8.0-openjdk.ppc64le java-1.8.0-openjdk-devel.ppc64le
export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-)(?=.*ppc64le)')
export PATH=$PATH:$JAVA_HOME/bin

#Clone the repo.
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $VERSION

#Build and test the package
mvn test
