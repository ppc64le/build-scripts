# ----------------------------------------------------------------------------
#
# Package       : animal-sniffer
# Version       : animal-sniffer-parent-1.17 / animal-sniffer-parent-1.14
# Source repo   : https://github.com/mojohaus/animal-sniffer
# Tested on		: UBI 8.5
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Saurabh Gore <Saurabh.Gore@ibm.com> 
#
# Disclaimer: This script has been tested in root mode on given
# ========== platform using the mentioned version of the package.
# It may not work as expected with newer versions of the
# package and/or distribution. In such case, please
# contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

#Variables
PACKAGE_NAME=animal-sniffer
PACKAGE_VERSION="${1:-animal-sniffer-parent-1.17}"
PACKAGE_URL=https://github.com/mojohaus/animal-sniffer.git


# Install required files
yum install -y git maven java-1.8.0-openjdk-devel

#Clonning repo
git clone $PACKAGE_URL
cd $PACKAGE_NAME

git checkout $PACKAGE_VERSION

#Build without tests
mvn clean package -DskipTests

#To execute tests
if ! mvn test ; then   
	echo "------------------Build Success but test fails---------------------"
else
	echo "------------------Build and test success-------------------------"
fi
