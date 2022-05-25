#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : method_source
# Version       : v0.8.2,v0.9.0,v0.9.2,v1.0.0
# Source repo   : https://github.com/banister/method_source
# Tested on     : UBI: 8.5
# Language      : Ruby
# Travis-Check  : True
# Script License: Apache License 2.0
# Maintainer's  : Balavva Mirji <Balavva.Mirji@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


set -e

PACKAGE_NAME=method_source
PACKAGE_VERSION=${1:-v0.9.2}            
PACKAGE_URL=https://github.com/banister/method_source

yum install git ruby ruby-devel -y
gem install bundle

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

export BUNDLE_GEMFILE=$PWD/Gemfile

which bundle || gem install bundler
gem update bundler

bundle install --verbose
bundle exec rake
