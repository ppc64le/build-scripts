#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : jekyll-theme-midnight
# Version       : v0.1.1
# Source repo	: https://github.com/pages-themes/midnight
# Tested on     : UBI 8.5
# Language      : Ruby
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Valen Mascarenhas <Valen.Mascarenhas@ibm.com> 
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=midnight
PACKAGE_VERSION=${1:-v0.1.1}
PACKAGE_URL=https://github.com/pages-themes/midnight

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

sed -i '4 a  Style/FrozenStringLiteralComment: \n Enabled: false \n' .rubocop.yml
sed -i "2 a gem 'kramdown-parser-gfm'" Gemfile
sed -i "13 a  s.required_ruby_version = '>= 2.4.0'" jekyll-theme-midnight.gemspec
sed -i '14 s/^/  /'  jekyll-theme-midnight.gemspec
sed -i 's/linear_gradient/linear-gradient/' _sass/jekyll-theme-midnight.scss
sed -i "22 a <ul> " _layouts/default.html
sed -i "29 a </ul> " _layouts/default.html
sed -i 's/Metrics/Layout/' .rubocop.yml

if ! script/bootstrap; then
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