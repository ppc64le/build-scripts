#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: docile
# Version	: v1.1.5
# Source repo	: https://github.com/ms-ati/docile
# Tested on	: UBI: 8.5
# Language      : Ruby
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Sunidhi Gaonkar/Vedang Wartikar <Vedang.Wartikar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=docile
PACKAGE_VERSION=${1:-v1.1.5}
PACKAGE_URL=https://github.com/ms-ati/docile

yum install git make gcc ruby ruby-devel redhat-rpm-config -y
gem install bundle
gem install bundler

mkdir -p /home/tester
cd /home/tester

git clone $PACKAGE_URL 
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

bundle install
bundle exec rspec
