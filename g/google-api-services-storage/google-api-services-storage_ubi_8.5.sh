# -----------------------------------------------------------------------------
#
# Package	: google-api-services-storage
# Version	: 4eede80f0be5b7352f5a1698be5be8d2a1da4ca1
# Source repo	: https://github.com/googleapis/google-api-java-client-services
# Tested on	: UBI 8.5
# Language	: JAVA
# Travis-Check	:True
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
PACKAGE_DIR=google-api-java-client-services/clients/google-api-services-storage/v1/1.27.0
PACKAGE_COMMIT=${1:-4eede80f0be5b7352f5a1698be5be8d2a1da4ca1}
PACKAGE_URL=https://github.com/googleapis/google-api-java-client-services


mkdir -p output

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

yum install git maven -y

#clone the repository
git clone $PACKAGE_URL

export WORK_DIR=$HOME_DIR/$PACKAGE_DIR
cd $WORK_DIR
git checkout $PACKAGE_COMMIT

if ! mvn clean install -DskipTests; then
	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_COMMIT $PACKAGE_NAME" > $HOME_DIR/output/install_fails
	echo "$PACKAGE_NAME  |  $PACKAGE_COMMIT | $OS_NAME | GitHub | Fail |  Install_Fails" > $HOME_DIR/output/version_tracker
	exit 1
fi
	
if ! mvn test; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME" > $HOME_DIR/output/test_fails 
	echo "$PACKAGE_NAME  |  $PACKAGE_COMMIT | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" > $HOME_DIR/output/version_tracker
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME" > $HOME_DIR/output/test_success 
	echo "$PACKAGE_NAME  |  $PACKAGE_COMMIT | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > $HOME_DIR/output/version_tracker
	find -name *.jar >> $HOME_DIR/output/post_build_jars.txt
	echo "------------PATH of .JAR created for $WORK_DIR can be checked in text file:$HOME_DIR/output/post_build_jars.txt -----------"
	exit 0
fi

