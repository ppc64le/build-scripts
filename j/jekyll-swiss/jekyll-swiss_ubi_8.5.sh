#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: jekyll-swiss
# Version	: master
# Source repo	: https://github.com/broccolini/swiss.git
# Tested on	: UBI: 8.5
# Language      : Ruby
# Travis-Check  : False
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

PACKAGE_NAME=swiss
PACKAGE_VERSION=master
PACKAGE_URL=https://github.com/broccolini/swiss.git

yum -y update && yum install -y nodejs nodejs-devel nodejs-packaging npm python38 python38-devel ncurses git jq curl make gcc-c++ procps gnupg2 ruby libcurl-devel libffi-devel ruby-devel redhat-rpm-config sqlite sqlite-devel java-1.8.0-openjdk-devel rubygem-rake

gem install bundle
gem install bundler:1.17.3
gem install kramdown-parser-gfm

gem install rubygems-update
update_rubygems
gem update --system

git clone $PACKAGE_URL
cd $PACKAGE_NAME

sed -i '18d' jekyll-swiss.gemspec && sed -i '18i spec.add_development_dependency "bundler"' jekyll-swiss.gemspec
sed -i '$ a\gem "kramdown-parser-gfm"' Gemfile 

if ! bundle install; then
	echo "------------------Build_Install_fails---------------------"
	exit 1
else
	echo "------------------Build_Install_success-------------------------"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION |"
fi

if ! bundle exec jekyll serve; then
	echo "------------------Test_fails---------------------"
else
	echo "------------------Test_success-------------------------"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION |"
fi

# Tested on VM, everything worked.
# On Travis it is failing due to encoding. Hence, disabling the Travis check.

#Build and test logs:
# Fetching gem metadata from https://rubygems.org/..........
# Resolving dependencies...
# Fetching rake 10.5.0
# Installing rake 10.5.0
# Fetching public_suffix 4.0.6
# Using bundler 2.3.9
# Fetching concurrent-ruby 1.1.9
# Fetching eventmachine 1.2.7
# Fetching ffi 1.15.5
# Fetching colorator 1.1.0
# Fetching forwardable-extended 2.6.0
# Fetching http_parser.rb 0.8.0
# Fetching rb-fsevent 0.11.1
# Installing colorator 1.1.0
# Installing forwardable-extended 2.6.0
# Installing public_suffix 4.0.6
# Installing rb-fsevent 0.11.1
# Using rexml 3.2.5
# Fetching liquid 4.0.3
# Fetching mercenary 0.3.6
# Installing http_parser.rb 0.8.0 with native extensions
# Installing mercenary 0.3.6
# Installing liquid 4.0.3
# Installing concurrent-ruby 1.1.9
# Installing eventmachine 1.2.7 with native extensions
# Fetching rouge 3.28.0
# Fetching safe_yaml 1.0.5
# Using jekyll-swiss 1.0.0 from source at `.`
# Using kramdown 2.3.2
# Fetching pathutil 0.16.2
# Installing safe_yaml 1.0.5
# Installing pathutil 0.16.2
# Fetching addressable 2.8.0
# Installing ffi 1.15.5 with native extensions
# Installing addressable 2.8.0
# Installing rouge 3.28.0
# Using kramdown-parser-gfm 1.1.0
# Fetching i18n 0.9.5
# Installing i18n 0.9.5
# Fetching rb-inotify 0.10.1
# Installing rb-inotify 0.10.1
# Fetching sass-listen 4.0.0
# Fetching listen 3.7.1
# Installing listen 3.7.1
# Installing sass-listen 4.0.0
# Fetching sass 3.7.4
# Fetching jekyll-watch 2.2.1
# Installing jekyll-watch 2.2.1
# Installing sass 3.7.4
# Fetching jekyll-sass-converter 1.5.2
# Installing jekyll-sass-converter 1.5.2
# Fetching em-websocket 0.5.3
# Installing em-websocket 0.5.3
# Fetching jekyll 3.9.1
# Installing jekyll 3.9.1
# Bundle complete! 5 Gemfile dependencies, 29 gems now installed.
# Use `bundle info [gemname]` to see where a bundled gem is installed.

# ------------------Build_Install_success-------------------------
# swiss  | master |

# Configuration file: /swiss/_config.yml
#             Source: /swiss
#        Destination: /swiss/_site
# Incremental build: disabled. Enable with --incremental
#       Generating...
#                     done in 0.682 seconds.
# Auto-regeneration: enabled for '/swiss'
#     Server address: http://127.0.0.1:4000/
#   Server running... press ctrl-c to stop.
# ^C------------------Test_success-------------------------
# swiss  | master |