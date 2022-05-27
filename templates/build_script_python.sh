#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: {package_name}
# Version	: {package_version}
# Source repo	: {package_url}
# Tested on	: {distro_name} {distro_version}
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: BulkPackageSearch Automation {maintainer}
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=${PACKAGE_NAME}
PACKAGE_VERSION=${PACKAGE_VERSION}
PACKAGE_URL=${PACKAGE_URL}

yum -y update && yum install -y python38 python38-devel python39 python39-devel python2 python2-devel python3 python3-devel ncurses git gcc gcc-c++ libffi libffi-devel sqlite sqlite-devel sqlite-libs python3-pytest make cmake

mkdir -p /home/tester/output
cd /home/tester

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

SOURCE=Github

pip3 install -r /home/tester/output/requirements.txt

pip3 freeze > /home/tester/output/available_packages.txt

PACKAGE_INFO=`cat /home/tester/output/available_packages.txt | grep $PACKAGE_NAME`

if ! test -z "$PACKAGE_INFO"; then
	PACKAGE_VERSION=$(echo $PACKAGE_INFO | cut -d  "="  -f 3)
	SOURCE="Distro"
	echo "------------------$PACKAGE_NAME:install_and_test_both_success-------------------------"
	echo  $PACKAGE_INFO > /home/tester/output/test_success 
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
	exit 0
fi

function build_test_with_python2(){
	SOURCE="Python 2.7"
	cd /home/tester/$PACKAGE_NAME
	if ! python2 setup.py install; then
		echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
		echo  "$PACKAGE_URL $PACKAGE_NAME " > /home/tester/output/install_fails
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail |  Install_Fails" > /home/tester/output/version_tracker
		exit 1
	fi

	cd /home/tester/$PACKAGE_NAME

	if ! python2 setup.py test; then
		echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
		echo  "$PACKAGE_URL $PACKAGE_NAME "  > /home/tester/output/test_fails
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail |  Install_success_but_test_Fails" > /home/tester/output/version_tracker
		exit 1
	else
		echo "------------------$PACKAGE_NAME:install_and_test_both_success-------------------------"
		echo  "$PACKAGE_URL $PACKAGE_NAME "  > /home/tester/output/test_success 
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
		exit 0
	fi
}

if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
    	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/clone_fails
		echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail |  Clone_Fails" > /home/tester/output/version_tracker
    	exit 1
fi

cd /home/tester/$PACKAGE_NAME
git checkout $PACKAGE_VERSION
if ! python3 setup.py install; then
    build_test_with_python2
	exit 0
fi

cd /home/tester/$PACKAGE_NAME

if ! python3 setup.py test; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo  "$PACKAGE_URL $PACKAGE_NAME "  > /home/tester/output/test_fails
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail |  Install_success_but_test_Fails" > /home/tester/output/version_tracker
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_and_test_both_success-------------------------"
	echo  "$PACKAGE_URL $PACKAGE_NAME "  > /home/tester/output/test_success 
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
	exit 0
fi
