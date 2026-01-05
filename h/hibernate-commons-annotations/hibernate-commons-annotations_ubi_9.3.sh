#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : hibernate-commons-annotations
# Version          : 7.0.0.Final
# Source repo      : https://github.com/hibernate/hibernate-commons-annotations.git
# Tested on        : UBI 9.3
# Language         : Java
# Ci-Check     : True 
# Script License   : Apache License, Version 2 or later
# Maintainer       : Pooja Shah <Pooja.Shah4@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=hibernate-commons-annotations
PACKAGE_VERSION=${1:-7.0.0.Final}
PACKAGE_URL=https://github.com/hibernate/hibernate-commons-annotations.git

# Install dependencies.
yum install -y yum-utils git wget tar java-11-openjdk-devel

# Clone hibernate-commons-annotations repo
git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Update the version of nu.studer:gradle-credentials-plugin
sed -i 's/2.1/2.2/g' build.gradle

if ! ./gradlew clean build -x test; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
elif ! ./gradlew test; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Both_Install_and_Test_Success"
	exit 0
fi
