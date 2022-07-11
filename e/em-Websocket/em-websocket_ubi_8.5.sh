#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : em-websocket
# Version       : v0.5.1
# Source repo   : http://github.com/igrigorik/em-websocket
# Tested on     : UBI: 8.5
# Language      : Ruby
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Shreya Kajbaje <Shreya.Kajbaje@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=em-websocket
PACKAGE_VERSION=v0.5.1
PACKAGE_URL=https://github.com/igrigorik/em-websocket

yum -y update && yum install -y nodejs nodejs-devel nodejs-packaging npm python38 python38-devel ncurses git jq curl make gcc-c++ procps gnupg2 ruby libcurl-devel libffi-devel ruby-devel redhat-rpm-config sqlite sqlite-devel java-1.8.0-openjdk-devel rubygem-rake

gem install bundle
gem install bundler:1.17.3
gem install rake
gem install kramdown-parser-gfm

mkdir -p /home/tester
cd /home/tester

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

sed -i 's~git@github.com:movitto/em-websocket-client.git~https://github.com/movitto/em-websocket-client.git~g' Gemfile

if ! bundle install; then
        echo "------------------Build_Install_fails---------------------"
        exit 1
else
        echo "------------------Build_Install_success-------------------------"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION |"
fi

if ! bundle exec rspec; then
        echo "------------------Test_fails---------------------"
        exit 1
else
        echo "------------------Test_success-------------------------"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION |"
fi