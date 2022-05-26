#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: jekyll-sitemap
# Version	: v1.2.0
# Source repo	: https://github.com/jekyll/jekyll-sitemap
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

PACKAGE_NAME=jekyll-sitemap
PACKAGE_VERSION=${1:-v1.2.0}
PACKAGE_URL=https://github.com/jekyll/jekyll-sitemap

yum -y update && yum install -y nodejs nodejs-devel nodejs-packaging npm python38 python38-devel ncurses git jq curl make gcc-c++ procps gnupg2 ruby libcurl-devel libffi-devel ruby-devel redhat-rpm-config sqlite sqlite-devel java-1.8.0-openjdk-devel rubygem-rake

gem install bundle
gem install bundler:1.17.3
gem install kramdown-parser-gfm

git clone $PACKAGE_URL 
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

sed -i '23d' jekyll-sitemap.gemspec && sed -i '23i spec.add_development_dependency "bundler"' jekyll-sitemap.gemspec
sed -i '$ a\gem "kramdown-parser-gfm"' Gemfile

gem install rubygems-update
update_rubygems
gem update --system

if ! bundle install; then
	echo "------------------Build_Install_fails---------------------"
else
	echo "------------------Build_Install_success-------------------------"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION |"
fi

chmod u+x script/cibuild

if ! script/test; then
	echo "------------------Test_fails---------------------"
else
	echo "------------------Test_success-------------------------"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION |"
fi
