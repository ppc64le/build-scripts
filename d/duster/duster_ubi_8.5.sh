#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : duster
# Version       : v0.3.2
# Source repo	: https://github.com/tighten/duster.git
# Tested on     : ubi 8.5
# Language      : php
# Travis-Check  : true
# Script License: Apache License, Version 2 or later
# Maintainer	: Sachin K {sachin.kakatkar@ibm.com}
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#Run the script:./duster_ubi_8.5.sh v0.3.2(version_to_test) 
PACKAGE_NAME=duster
PACKAGE_VERSION=v0.3.2
PACKAGE_URL=https://github.com/tighten/duster.git

dnf module enable php:7.3 -y
dnf install git php php-cli php-common python3 php-json php-dom unzip php-mbstring -y

#install composer
curl -sS https://getcomposer.org/installer | php
cp composer.phar /usr/bin/
ln -sf /usr/bin/composer.phar /usr/bin/composer

mkdir -p /home/tester/output
cd /home/tester

PACKAGE_VERSION=${1:-v0.3.2}

install_test_NA_update()
{
	echo 
    echo "------------------$PACKAGE_NAME:install_success_&_test_NA-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/test_success 
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Install_Success_and_Test_NA" > /home/tester/output/version_tracker
    exit 0
}


OS_NAME=$(python3 -c "os_file_data=open('/etc/os-release').readlines();os_info = [i.replace('PRETTY_NAME=','').strip() for i in os_file_data if i.startswith('PRETTY_NAME')];print(os_info[0])")

rm -rf $PACKAGE_NAME

if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
  	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/clone_fails
    echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails" > /home/tester/output/version_tracker
  	exit 1
fi

cd /home/tester/$PACKAGE_NAME
git checkout $PACKAGE_VERSION

INSTALL_SUCCESS="false"


if ! composer -n install; then
	INSTALL_SUCCESS="false"
	else
	INSTALL_SUCCESS="true"
fi


if [ $INSTALL_SUCCESS == "false" ]
then
	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/install_fails
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails" > /home/tester/output/version_tracker
	exit 1
fi

cd /home/tester/$PACKAGE_NAME

#No test cases
install_test_NA_update

