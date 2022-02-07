#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : paping
# Version       : v1.5.5
# Source repo   : https://github.com/koolhazz/paping.git
# Tested on     : ubi 8.5
# Language      : c++
# Travis-Check  : true
# Script License: Apache License Version 2.0
# Maintainer    : sachin.kakatkar@ibm.com
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#Run the script:./paping_ubi_8.5.sh v1.5.5(version_to_test)
PACKAGE_NAME=paping
PACKAGE_VERSION=$1
PACKAGE_URL=https://github.com/koolhazz/paping.git
dnf install git make gcc-c++ -y

if [ -z "$1" ]
  then
    PACKAGE_VERSION=v1.5.5
fi


mkdir -p /home/tester/output
cd /home/tester

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

#Remove older package if any
rm -rf $PACKAGE_NAME

#Clone the package
if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
    	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/clone_fails
        echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails" > /home/tester/output/version_tracker
    	exit 0
fi

cd /home/tester/$PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Install package and dependency
if ! g++ -m64 ./src/print.cpp ./src/stats.cpp ./src/timer.cpp ./src/arguments.cpp ./src/i18n.cpp ./src/host.cpp ./src/socket.cpp ./src/main.cpp -o /bin/paping; then
     	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/install_fails
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails" > /home/tester/output/version_tracker
	exit 1
fi

#Run the test cases
cd /home/tester/$PACKAGE_NAME
if ! paping www.google.com -p 80 -c 4; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/test_fails 
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" > /home/tester/output/version_tracker
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/test_success 
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
	exit 0
fi

