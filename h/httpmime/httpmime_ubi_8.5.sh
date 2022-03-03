#! /bin/bash
# -----------------------------------------------------------------------------
# Package		: httpmime
# Version		: rel/v4.1.2
# Source repo	: https://github.com/apache/httpcomponents-client
# Tested on		: UBI 8.5
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Saurabh Gore <Saurabh.Gore@ibm.com> 
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

PACKAGE_NAME=httpcomponents-client
PACKAGE_VERSION=${1:-rel/v4.1.2}  
PACKAGE_URL=https://github.com/apache/httpcomponents-client.git


dnf install git java-1.8.0-openjdk-devel maven -y

# clone package
git clone $PACKAGE_URL

cd $PACKAGE_NAME

git checkout $PACKAGE_VERSION

#To Build 
cd httpmime
mvn install -DskipTests

#To execute tests
if ! mvn test ; then   
	echo "------------------Build Success but test fails---------------------"
else
	echo "------------------Build and test success-------------------------"
fi
