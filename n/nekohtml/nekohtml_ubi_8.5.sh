# -----------------------------------------------------------------------------
#
# Package	: nekohtml
# Version	: nekohtml-1.9.22
# Source repo	: https://github.com/codelibs/nekohtml
# Tested on	: UBI 8.5
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Sapna Shukla <Sapna.Shukla@ibm.com>
# Language 	: Java
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#-----------------------------------------------------------------------------
# PACKAGE_VERSION parameter for the script
# nektml has tags as nekohtml-<version_number>
# If the script is run without any parameter it builds and validate nekohtml-1.9.22
# To run the script for other specific versions provide just the tag/version number ie., ./nekohtml_ubi8.4.sh 1.9.22
#-----------------------------------------------------------------------------

HOME_DIR=`pwd`
PACKAGE_NAME=nekohtml
PACKAGE_VERSION=${1:-1.9.22}
PACKAGE_URL=https://github.com/codelibs/nekohtml

mkdir -p output

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

yum install git maven -y

#clone the repository
git clone $PACKAGE_URL

export WORK_DIR=$HOME_DIR/$PACKAGE_NAME
cd $WORK_DIR
CHECKOUT_VAL=nekohtml-$PACKAGE_VERSION
git checkout $CHECKOUT_VAL

if ! mvn clean install ; then
	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION  | $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_success_no_test_availabe-------------------------"
	echo "$PACKAGE_NAME | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Install_Success"
	find -name *.jar >> $HOME_DIR/output/post_build_jars.txt
	echo "PATH of .JAR created for $WORK_DIR can be checked in text file:$HOME_DIR/output/post_build_jars.txt"
	exit 0
fi

