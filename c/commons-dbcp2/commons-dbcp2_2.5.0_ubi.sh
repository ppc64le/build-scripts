#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : commons-dbcp2
# Version       : 2.5.0
# Source repo   : https://github.com/apache/commons-dbcp
# Tested on     : UBI: 8.4
# Language      : Java
# Travis-Check  : True
# Script License: Apache License 2.0
# Maintainer's  : Mohit Pawar <mohit.pawar@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

PACKAGE_NAME=commons-dbcp-
PACKAGE_VERSION=${1:-2.5.0}              
PACKAGE_URL=https://github.com/apache/commons-dbcp

yum install -y git maven

# clone package
git clone $PACKAGE_URL
cd commons-dbcp
git checkout $PACKAGE_NAME$PACKAGE_VERSION

#build
mvn clean install -DskipTests

#test
mvn test
