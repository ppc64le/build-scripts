# -----------------------------------------------------------------------------
# Package	: grails
# Version	: v5.0.2,v5.2.5
# Source repo	: https://github.com/grails/grails-core.git
# Tested on	: ubi 8.5
# Language	: Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Sapna Shukla <Sapna.Shukla@ibm.com>,Pratik Tonage <Pratik.Tonage@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

HOME_DIR=`pwd`
PACKAGE_NAME=grails-core
PACKAGE_VERSION=${1:-v5.2.5}
PACKAGE_URL=https://github.com/grails/grails-core.git
mkdir -p /home/tester

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

# Install required dependencies
yum install git unzip wget maven -y

#clone the repository
git clone $PACKAGE_URL

export WORK_DIR=$HOME_DIR/$PACKAGE_NAME
cd $WORK_DIR
git checkout $PACKAGE_VERSION

#Build	
if ! ./gradlew install; then
	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1
fi

#Test
if ! ./gradlew test; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
	exit 0
fi
