#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: bump
# Version	: v0.8.0
# Source repo	: https://github.com/gregorym/bump
# Tested on	: UBI 8.4
# Language      : Ruby
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer	: Sapana Khemkar {Sapana.khemkar@ibm.com}
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME=bump
PACKAGE_VERSION=${1-"v0.8.0"}
PACKAGE_URL=https://github.com/gregorym/bump

yum install -y gcc git make ruby ruby-devel redhat-rpm-config

gem install bundle
gem install rake

mkdir -p /home/tester/output
cd /home/tester


git clone $PACKAGE_URL $PACKAGE_NAME
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

bundle install

git config --global user.email "you@example.com"
git config --global user.name "Your Name"
bundle exec rake spec

exit 0
