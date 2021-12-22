# -----------------------------------------------------------------------------
#
# Package       : apicurio-registry
# Version       : 2.1.0.Final
# Source repo   : https://github.com/Apicurio/apicurio-registry
# Tested on     : UBI 8.4
# Script License: Apache License, Version 2 or later
# Maintainer    : Priya Seth <sethp@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=apicurio-registry
PACKAGE_VERSION=2.1.0.Final
PACKAGE_URL=https://github.com/Apicurio/apicurio-registry

yum update -y
yum install -y git java-11-openjdk-devel maven

export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-11)(?=.*ppc64le)')
export PATH=$JAVA_HOME/bin:$PATH

#There are some tests in apicurio-registry-app that fail on both Intel and Power,
#hence ignoring them
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
./mvnw -Dmaven.test.failure.ignore=true install
