#!/bin/bash -e

# ----------------------------------------------------------------------------
#
# Package               : i18n_data
# Version               : v0.7.0
# Source repo           : https://github.com/grosser/i18n_data
# Tested on             : UBI 8.5
# Language              : Ruby
# Travis-Check          : True
# Script License        : Apache License, Version 2 or later
# Maintainer            : Vathsala . <vaths367@in.ibm.com>
#
# Disclaimer            : This script has been tested in root mode on given
# ==========              platform using the mentioned version of the package.
#                         It may not work as expected with newer versions of the
#                         package and/or distribution. In such case, please
#                         contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

if [ -z "$1" ]; then
  export PACKAGE_VERSION=${1:-v0.7.0}
else
  export PACKAGE_VERSION=$1
fi
if [ -d "i18n_data" ] ; then
  rm -rf i18n_data
fi

yum install git ruby ruby-devel -y
gem install bundle

git clone https://github.com/grosser/i18n_data
cd i18n_data
git checkout $PACKAGE_VERSION
ret=$?
if [ $ret -eq 0 ] ; then
 echo "$PACKAGE_VERSION found to checkout "
else
 echo "$PACKAGE_VERSION not found "
 exit
fi

export BUNDLE_GEMFILE=$PWD/Gemfile

which bundle || gem install bundler
gem update bundler

#Observed 24 failures:rake aborted and all are in parity with Intel 
#rake aborted!
#Command failed with status (1): [rspec --warnings spec/...]
#/root/rubybuildscripts/i18n_data/Rakefile:8:in `block in <top (required)>'
#/usr/local/rvm/gems/ruby-2.7.2/bin/ruby_executable_hooks:22:in `eval'
#/usr/local/rvm/gems/ruby-2.7.2/bin/ruby_executable_hooks:22:in `<main>'
#Tasks: TOP => default
#Build and test

bundle install --verbose
ret=$?
if [ $ret -ne 0 ] ; then
  echo "Build failed "
else
  bundle exec rake
  ret=$?
  if [ $ret -ne 0 ] ; then
    echo "Tests failed "
  else
    echo "Build & unit tests Successful "
  fi
fi


