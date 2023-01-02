#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: fluentd
# Version	: v1.14.5
# Source repo	: https://github.com/fluent/fluentd
# Tested on	: UBI: 8.5
# Language      : Ruby
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Muskaan Sheik <Muskaan.Sheik@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=fluentd
PACKAGE_VERSION=${1:-v1.14.5}
PACKAGE_URL=https://github.com/fluent/fluentd

yum -y update && yum install -y nodejs nodejs-devel nodejs-packaging npm python38 python38-devel ncurses git jq curl make gcc-c++ procps gnupg2 ruby libcurl-devel libffi-devel ruby-devel redhat-rpm-config sqlite sqlite-devel java-1.8.0-openjdk-devel rubygem-rake ruby rubygems wget

gem sources --add https://rubygems.org/
wget https://rubygems.org/rubygems/rubygems-3.3.15.tgz
tar zxvf rubygems-3.3.15.tgz
cd rubygems-3.3.15
ruby setup.rb

cd ..
git clone $PACKAGE_URL
cd fluentd
git checkout $PACKAGE_VERSION

gem install bundler
bundle install --path vendor/bundle

bundle exec rake test TEST=test/test_*.rb