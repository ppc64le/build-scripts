#!/bin/bash -e
# ----------------------------------------------------------------------------
# Package          : type-parser
# Version          : master
# Source repo      : https://github.com/drapostolos/type-parser.git
# Tested on        : UBI 8.5
# Language         : Java
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : valipi_venkatesh@persistent.com
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
# ----------------------------------------------------------------------------

PACKAGE_NAME=type-parser
PACKAGE_URL=https://github.com/drapostolos/type-parser.git
PACKAGE_VERSION=master
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

#Dependencies
yum install -y java-17-openjdk java-17-openjdk-devel java-17-openjdk-headless wget git 
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$PATH:$JAVA_HOME/bin

# Cloning the repository from remote to local
git clone $PACKAGE_URL
cd $PACKAGE_NAME
if ! ./gradlew ; then
        echo "------------------$PACKAGE_NAME:Build_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
	exit 1
fi

if ! ./gradlew test ; then
        echo "------------------$PACKAGE_NAME::Build_success_but_Test_fails-------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail|  Build_success_but_Test_fails"
	exit 2
else
	echo "------------------$PACKAGE_NAME::Build_and_Test_success-------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
        exit 0
fi








