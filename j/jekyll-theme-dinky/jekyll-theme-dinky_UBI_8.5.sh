#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: jekyll-theme-dinky
# Version	: v0.1.1
# Source repo	: https://github.com/pages-themes/dinky
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

PACKAGE_NAME=dinky
PACKAGE_VERSION=${1:-v0.1.1}
PACKAGE_URL=https://github.com/pages-themes/dinky

export LC_ALL="en_US.UTF-8"
export LANG="en_US.UTF-8"

yum -y update && yum install -y nodejs nodejs-devel nodejs-packaging npm python38 python38-devel ncurses git jq curl make gcc-c++ procps gnupg2 ruby libcurl-devel libffi-devel ruby-devel redhat-rpm-config sqlite sqlite-devel java-1.8.0-openjdk-devel rubygem-rake 

gem install bundle
gem install bundler
gem install kramdown-parser-gfm

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

sed -i '1i # frozen_string_literal: true\n' Gemfile
sed -i "$ a\gem 'kramdown-parser-gfm'" Gemfile
sed -i '1i # frozen_string_literal: true\n' jekyll-theme-dinky.gemspec
sed -i "16i\  s.required_ruby_version = '>= 2.4.0'" jekyll-theme-dinky.gemspec
sed -i '2i # frozen_string_literal: true' script/validate-html

if ! script/bootstrap; then
	echo "------------------Build_Install_fails---------------------"
	exit 1
else
	echo "------------------Build_Install_success-------------------------"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION |"
fi

chmod u+x script/cibuild

if ! script/cibuild; then
	echo "------------------Test_fails---------------------"
	exit 1
else
	echo "------------------Test_success-------------------------"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION |"
fi

# Tested on VM, everything worked.
# On Travis it is failing due to encoding. Hence, disabling the Travis check.

#Build and test logs:
# Fetching gem metadata from https://rubygems.org/..........
# Resolving dependencies....
# Using bundler 2.3.9
# Fetching http_parser.rb 0.8.0
# Fetching ffi 1.15.5
# Fetching public_suffix 4.0.6
# Fetching concurrent-ruby 1.1.9
# Fetching colorator 1.1.0
# Fetching forwardable-extended 2.6.0
# Fetching ast 2.4.2
# Fetching eventmachine 1.2.7
# Installing forwardable-extended 2.6.0
# Installing colorator 1.1.0
# Installing ast 2.4.2
# Installing public_suffix 4.0.6
# Installing http_parser.rb 0.8.0 with native extensions
# Installing eventmachine 1.2.7 with native extensions
# Installing concurrent-ruby 1.1.9
# Installing ffi 1.15.5 with native extensions
# Fetching mercenary 0.3.6
# Installing mercenary 0.3.6
# Fetching mini_portile2 2.6.1
# Fetching parallel 1.21.0
# Fetching racc 1.6.0
# Fetching rainbow 3.1.1
# Fetching yell 2.2.2
# Installing racc 1.6.0 with native extensions
# Installing parallel 1.21.0
# Installing mini_portile2 2.6.1
# Installing rainbow 3.1.1
# Installing yell 2.2.2
# Fetching rb-fsevent 0.11.1
# Using rexml 3.2.5
# Fetching liquid 4.0.3
# Fetching rouge 3.28.0
# Fetching safe_yaml 1.0.5
# Installing rb-fsevent 0.11.1
# Installing safe_yaml 1.0.5
# Installing liquid 4.0.3
# Installing rouge 3.28.0
# Fetching json 2.6.1
# Installing json 2.6.1 with native extensions
# Fetching regexp_parser 2.2.1
# Fetching ruby-progressbar 1.11.0
# Fetching unicode-display_width 1.8.0
# Installing ruby-progressbar 1.11.0
# Installing unicode-display_width 1.8.0
# Installing regexp_parser 2.2.1
# Fetching pathutil 0.16.2
# Installing pathutil 0.16.2
# Fetching addressable 2.8.0
# Fetching parser 3.1.1.0
# Fetching i18n 0.9.5
# Installing addressable 2.8.0
# Installing i18n 0.9.5
# Using kramdown 2.3.1
# Using kramdown-parser-gfm 1.1.0
# Installing parser 3.1.1.0
# Fetching rubocop-ast 1.16.0
# Installing rubocop-ast 1.16.0
# Fetching rubocop 0.93.1
# Installing rubocop 0.93.1
# Fetching nokogiri 1.12.5
# Installing nokogiri 1.12.5 with native extensions
# Fetching ethon 0.15.0
# Fetching rb-inotify 0.10.1
# Installing rb-inotify 0.10.1
# Installing ethon 0.15.0
# Fetching listen 3.7.1
# Fetching sass-listen 4.0.0
# Installing listen 3.7.1
# Installing sass-listen 4.0.0
# Fetching typhoeus 1.4.0
# Installing typhoeus 1.4.0
# Fetching sass 3.7.4
# Fetching jekyll-watch 2.2.1
# Installing jekyll-watch 2.2.1
# Installing sass 3.7.4
# Fetching jekyll-sass-converter 1.5.2
# Installing jekyll-sass-converter 1.5.2
# Fetching nokogumbo 2.0.5
# Installing nokogumbo 2.0.5 with native extensions
# Fetching em-websocket 0.5.3
# Installing em-websocket 0.5.3
# Fetching w3c_validators 1.3.6
# Installing w3c_validators 1.3.6
# Fetching jekyll 3.9.1
# Installing jekyll 3.9.1
# Fetching jekyll-seo-tag 2.8.0
# Installing jekyll-seo-tag 2.8.0
# Using jekyll-theme-dinky 0.1.1 from source at `.`
# Fetching html-proofer 3.19.1
# Installing html-proofer 3.19.1
# Bundle complete! 5 Gemfile dependencies, 48 gems now installed.
# Use `bundle info [gemname]` to see where a bundled gem is installed.

# ------------------Build_Install_success-------------------------
# dinky  | v0.1.1 |

# Configuration file: /dinky/_config.yml
#             Source: /dinky
#        Destination: /dinky/_site
# Incremental build: disabled. Enable with --incremental
#       Generating...
#                     done in 0.612 seconds.
# Auto-regeneration: disabled. Use --watch to enable.
# Running ["ScriptCheck", "LinkCheck", "ImageCheck", "HtmlCheck"] on ["./_site"] on *.html...


# Ran on 2 files!


# HTML-Proofer finished successfully.
# Inspecting 3 files
# ...

# 3 files inspected, no offenses detected
# Checking index.html...
# Valid!
# Checking assets/css/style.css...
# Valid!
#   Successfully built RubyGem
#   Name: jekyll-theme-dinky
#   Version: 0.1.1
#   File: jekyll-theme-dinky-0.1.1.gem
# ------------------Test_success-------------------------
# dinky  | v0.1.1 |