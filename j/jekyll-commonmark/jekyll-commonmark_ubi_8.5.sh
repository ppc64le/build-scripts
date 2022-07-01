#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : jekyll-commonmark
# Version       : v1.2.0
# Source repo   : https://github.com/pathawks/jekyll-commonmark
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

PACKAGE_NAME=jekyll-commonmark
PACKAGE_VERSION=${1:-v1.2.0}
PACKAGE_URL=https://github.com/jekyll/jekyll-commonmark.git

yum -y update && yum install -y nodejs nodejs-devel nodejs-packaging npm python38 python38-devel ncurses git jq curl make gcc-c++ procps gnupg2 ruby libcurl-devel libffi-devel ruby-devel redhat-rpm-config sqlite sqlite-devel java-1.8.0-openjdk-devel rubygem-rake

gem pristine --all
gem install bundle
gem install bundler
gem install kramdown-parser-gfm
gem install rubygems-update
update_rubygems
gem update --system

mkdir -p /home/tester
cd /home/tester

git clone $PACKAGE_URL 
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

sed -i 's/1.15/2.3.16/' jekyll-commonmark.gemspec

if ! bundle install; then
	echo "------------------Build_Install_fails---------------------"
	exit 1
else
	echo "------------------Build_Install_success-------------------------"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION |"
fi

if ! script/cibuild; then
	echo "------------------Test_fails---------------------"
	exit 1
else
	echo "------------------Test_success-------------------------"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION |"
fi