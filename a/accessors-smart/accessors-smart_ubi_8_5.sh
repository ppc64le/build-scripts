#!/bin/bash
 -------------------------------------------------------------------------
# Package       : json-smart-v2
# Version       : 2.4.8
# Source repo   : https://github.com/netplex/json-smart-v2.git
# Tested on     : UBI 8.5
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Stuti.Wali@ibm.com
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


set -e
PACKAGE_NAME=json-smart-v2
PACKAGE_VERSION=${1:-2.4.8}
PACKAGE_URL=https://github.com/netplex/json-smart-v2.git

yum install -y git maven java-1.8.0-openjdk.ppc64le java-1.8.0-openjdk-devel.ppc64le
export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-)(?=.*ppc64le)')
export PATH=$PATH:$JAVA_HOME/bin

#clone the repo.
git clone $PACKAGE_URL
cd $PACKAGE_NAME/accessors-smart
git checkout $PACKAGE_VERSION

#build and test package
mvn install -Dtest=!"TestDateConvert#testDateJAPAN"

