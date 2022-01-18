# -----------------------------------------------------------------------------
#
# Package	: gethostname4j
# Version	: v0.0.2
# Source repo	: https://github.com/mattsheppard/gethostname4j
# Tested on	: UBI 8.5
# Language	: JAVA
# Travis-Check	: True
# Script License: Apache License, Version 2 or later
# Maintainer	: Sapna Shukla <Sapna.Shukla@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

HOME_DIR=`pwd`
PACKAGE_NAME=gethostname4j
PACKAGE_VERSION=${1:-v0.0.2}
PACKAGE_URL=https://github.com/mattsheppard/gethostname4j


mkdir -p output

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

yum install git maven -y

#clone the repository
git clone $PACKAGE_URL

export WORK_DIR=$HOME_DIR/$PACKAGE_NAME
cd $WORK_DIR
git checkout $PACKAGE_VERSION

if ! mvn clean install -DskipTests; then
	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME" > $HOME_DIR/output/install_fails
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails" > $HOME_DIR/output/version_tracker
	exit 1
fi
	
if ! mvn test; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME" > $HOME_DIR/output/test_fails 
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" > $HOME_DIR/output/version_tracker
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME" > $HOME_DIR/output/test_success 
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > $HOME_DIR/output/version_tracker
	find -name *.jar >> $HOME_DIR/output/post_build_jars.txt
	echo "------------PATH of .JAR created for $WORK_DIR can be checked in text file:$HOME_DIR/output/post_build_jars.txt -----------"
	exit 0
fi

