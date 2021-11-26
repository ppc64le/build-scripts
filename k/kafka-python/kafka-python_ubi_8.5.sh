# -----------------------------------------------------------------------------
#
# Package	: kafka-python
# Version	: 2.0.2
# Source repo	: https://github.com/dpkp/kafka-python
# Tested on	: UBI 8.5
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

PACKAGE_NAME=kafka-python
PACKAGE_VERSION=${1:-2.0.2}
PACKAGE_URL=https://github.com/dpkp/kafka-python

yum -y update && yum install -y python3 python3-devel git gcc java-1.8.0-openjdk wget

pip3 install tox

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

export KAFKA_VERSION=0.11.0.3

source $HOME_DIR/$PACKAGE_NAME/travis_java_install.sh
source $HOME_DIR/$PACKAGE_NAME/build_integration.sh

cd $HOME_DIR/$PACKAGE_NAME
if ! tox -e py36; then
	echo "------------------$PACKAGE_NAME:install_or_test_fails---------------------"
	echo  "$PACKAGE_URL $PACKAGE_NAME " 
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | Fail |  Install_or_test_Fails"
	exit 0
else
	echo "------------------$PACKAGE_NAME:install_and_test_both_success-------------------------"
	echo  "$PACKAGE_URL $PACKAGE_NAME " 
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME  | Pass |  Both_Install_and_Test_Success"
	exit 0
fi
