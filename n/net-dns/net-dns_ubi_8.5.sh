#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: net-dns
# Version	: 0.8.0
# Source repo	: https://github.com/bluemonk/net-dns.git
# Tested on	: UBI 8.5
# Language      : Ruby
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Raju Sah <Raju.Sah@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=net-dns
PACKAGE_VERSION=${1:-0.8.0}
PACKAGE_URL=https://github.com/bluemonk/net-dns.git


yum install -y gcc git make ruby ruby-devel redhat-rpm-config

gem install bundle
gem install rake

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)
HOME_DIR=`pwd`

if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
		echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME"
		echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
		exit 1
fi

cd $HOME_DIR/$PACKAGE_NAME
git checkout $PACKAGE_VERSION
if ! bundle install; then
		echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1
fi

cd $HOME_DIR/$PACKAGE_NAME
if ! bundle exec rspec; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
	exit 0
fi
