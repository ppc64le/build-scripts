# -----------------------------------------------------------------------------
#
# Package	: xalan-j
# Version	: xalan-j_2_7_2
# Source repo	: https://github.com/apache/xalan-j
# Tested on	: UBI 8.4
# Script License: Apache License, Version 2 or later
# Maintainer	: Atharv Phadnis <Atharv.Phadnis@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=xalan-j
PACKAGE_VERSION=xalan-j_2_7_2
PACKAGE_URL=https://github.com/apache/xalan-j

yum install -y java-1.8.0-openjdk-devel git wget

#Install ANT
wget https://downloads.apache.org/ant/binaries/apache-ant-1.10.12-bin.tar.gz
tar -xf apache-ant-1.10.12-bin.tar.gz
# Set ANT_HOME variable 
export ANT_HOME=${pwd}/apache-ant-1.10.12
# update the path env. variable 
export PATH=${PATH}:${ANT_HOME}/bin

HOME_DIR=`pwd`

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | Fail |  Clone_Fails"
	exit 0
fi

cd $HOME_DIR/$PACKAGE_NAME
git checkout $PACKAGE_VERSION

cd $HOME_DIR/$PACKAGE_NAME
if ! ant; then
	echo "------------------$PACKAGE_NAME:build_fails---------------------"
	echo  "$PACKAGE_URL $PACKAGE_NAME " 
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | Fail |  Build_Fails"
	exit 0
else
	echo "------------------$PACKAGE_NAME:build_success-------------------------"
	echo  "$PACKAGE_URL $PACKAGE_NAME " 
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | Pass |  Build_Success"
	exit 0
fi