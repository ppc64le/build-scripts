# -----------------------------------------------------------------------------
# Package		: xebia-servlet-extras
# Version		: xebia-servlet-extras-1.0.8
# Source repo   : https://github.com/xebia-france/xebia-servlet-extras
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

WORK_DIR=`pwd`

PACKAGE_NAME=xebia-servlet-extras
PACKAGE_VERSION=${1:-xebia-servlet-extras-1.0.8}  
PACKAGE_URL=https://github.com/xebia-france/xebia-servlet-extras.git


dnf install git  java-1.8.0-openjdk-devel maven -y

# clone package
cd $WORK_DIR
git clone $PACKAGE_URL

cd $PACKAGE_NAME

git checkout $PACKAGE_VERSION

# To Build 
mvn clean install -DskipTests

# To test
if ! mvn test ; then   
	echo "------------------Build Success but test fails---------------------"
else
	echo "------------------Build and test success-------------------------"
fi
