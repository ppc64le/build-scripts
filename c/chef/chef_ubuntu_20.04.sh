#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: chef
# Version	: v17.6.18
# Source repo	: https://github.com/chef/chef
# Tested on	: Ubuntu 20.04
# Language      : Ruby
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer	: Siddhesh Ghadi <Siddhesh.Ghadi@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME='chef'
PACKAGE_VERSION=${1:-v17.6.18}
PACKAGE_URL='https://github.com/chef/chef'

apt update -y
apt install -y git curl fakeroot

#install ruby 2.7 or above
cd $HOME
curl -sSL https://get.rvm.io | bash -s stable
source /usr/local/rvm/scripts/rvm
rvm -v
rvm install 2.7
ruby -v

cd $HOME
git clone -b ${PACKAGE_VERSION} ${PACKAGE_URL}
cd chef/omnibus
gem install bundler:2.2.22
bundle install
# build & create .deb file
bundle exec omnibus build chef
# genrated .deb file can be found in $HOME/chef/omnibus/pkg folder
ls pkg/

#Install .deb using
#dpkg -i package_file.deb
