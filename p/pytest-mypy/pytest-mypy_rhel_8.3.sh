# -----------------------------------------------------------------------------
#
# Package	: pytest-mypy
# Version	: 0.8.1
# Source repo	: https://github.com/dbader/pytest-mypy
# Tested on	: RHEL 8.3
# Script License: Apache License, Version 2 or later
# Maintainer	: BulkPackageSearch Automation <sethp@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=pytest-mypy
PACKAGE_VERSION=0.8.1
PACKAGE_URL=https://github.com/dbader/pytest-mypy

yum -y update && yum install -y python38 python38-devel python39 python39-devel python2 python2-devel python3 python3-devel ncurses git gcc gcc-c++ libffi libffi-devel sqlite sqlite-devel sqlite-libs python3-pytest make cmake

OS_NAME=`python3 -c "os_file_data=open('/etc/os-release').readlines();os_info = [i.replace('PRETTY_NAME=','').strip() for i in os_file_data if i.startswith('PRETTY_NAME')];print(os_info[0])"`

SOURCE=Github

pip3 install -r /home/tester/output/requirements.txt

pip3 freeze > /home/tester/output/available_packages.txt

PACKAGE_INFO=`cat available_packages.txt | grep $PACKAGE_NAME`
HOME_DIR=`pwd`
if ! test -z "$PACKAGE_INFO"; then
	PACKAGE_VERSION=$(echo $PACKAGE_INFO | cut -d  "="  -f 3)
	SOURCE="Distro"
	echo "------------------$PACKAGE_NAME:install_and_test_both_success-------------------------"
	echo  $PACKAGE_INFO
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE  | Pass |  Both_Install_and_Test_Success"
	exit 0
fi

function build_test_with_python2(){
	SOURCE="Python 2.7"
	cd $HOME_DIR/$PACKAGE_NAME
	if ! python2 setup.py install; then
		echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
		echo  "$PACKAGE_URL $PACKAGE_NAME "
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail |  Install_Fails"
		exit 0
	fi

	cd $HOME_DIR/$PACKAGE_NAME

	if ! python2 setup.py test; then
		echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
		echo  "$PACKAGE_URL $PACKAGE_NAME "
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail |  Install_success_but_test_Fails"
		exit 0
	else
		echo "------------------$PACKAGE_NAME:install_and_test_both_success-------------------------"
		echo  "$PACKAGE_URL $PACKAGE_NAME "
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE  | Pass |  Both_Install_and_Test_Success"
		exit 0
	fi
}

if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
    	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME"
		echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail |  Clone_Fails"
    	exit 0
fi

cd $HOME_DIR/$PACKAGE_NAME
git checkout $PACKAGE_VERSION
if ! python3 setup.py install; then
    build_test_with_python2
	exit 0
fi

cd $HOME_DIR/$PACKAGE_NAME

if ! python3 setup.py test; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo  "$PACKAGE_URL $PACKAGE_NAME "
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail |  Install_success_but_test_Fails"
	exit 0
else
	echo "------------------$PACKAGE_NAME:install_and_test_both_success-------------------------"
	echo  "$PACKAGE_URL $PACKAGE_NAME "
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE  | Pass |  Both_Install_and_Test_Success"
	exit 0
fi