#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: net-dns
# Version	: 0.9.0
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
PACKAGE_VERSION=${1:-v0.9.0}
PACKAGE_URL=https://github.com/bluemonk/net-dns.git


yum install -y gcc git make ruby ruby-devel redhat-rpm-config

gem install bundle
gem install rake

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)
HOME_DIR=`pwd`

if ! git clone $PACKAGE_URL; then
		echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME"
		echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
		exit 1
fi

cd $HOME_DIR/$PACKAGE_NAME
git checkout $PACKAGE_VERSION
bundle install
rake build 
rake testunit
