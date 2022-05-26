#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: rubyzip
# Version	: v1.2.1
# Source repo	: https://github.com/rubyzip/rubyzip
# Tested on	: UBI: 8.5
# Language      : Ruby
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Sunidhi Gaonkar<Sunidhi.Gaonkar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=rubyzip
PACKAGE_VERSION=${1:-v1.2.1}
PACKAGE_URL=https://github.com/rubyzip/rubyzip


yum install git make gcc ruby ruby-devel redhat-rpm-config -y

gem install bundle
gem install bundler
gem install rake

mkdir -p /home/tester
cd /home/tester

git clone $PACKAGE_URL 
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

bundle install
bundle exec rake
