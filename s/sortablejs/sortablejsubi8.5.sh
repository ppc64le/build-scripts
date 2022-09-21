#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : Sortable
# Version       : 1.10.2
# Source repo   : https://github.com/SortableJS/Sortable.git
# Tested on     : UBI 8.5
# Language      : Node
# Travis-Check  : true
# Script License: Apache License, Version 2 or later
# Maintainer    : BulkPackageSearch Automation {maintainer}
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=Sortable
PACKAGE_VERSION=1.10.2
PACKAGE_URL=https://github.com/SortableJS/Sortable.git

yum install postgresql-devel yum-utils nodejs nodejs-devel nodejs-packaging npm wget -y


npm install -g n
n lts

npm i -g npm-upgrade

yum install git -y
yum install make -y
yum install podman -y

wget https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/firefox-91.13.0-1.el8.ppc64le.rpm

if !(rpm -i firefox-91.13.0-1.el8.ppc64le.rpm);then
        echo "Issue in browser"
else
        echo "No issue in browser"
fi


rm -rf $PACKAGE_NAME

git clone $PACKAGE_URL


cd $PACKAGE_NAME

git checkout $PACKAGE_VERSION

if ! (npm install && npm audit fix && npm test) ; then
                        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
                        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | master  | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
                        exit 0
                else
                        echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
                        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | master | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
                        exit 0
                fi

