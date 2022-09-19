#!/bin/bash -e

# ----------------------------------------------------------------------------
#
# Package               : cells-erb
# Version               : v0.1.0
# Source repo           : https://github.com/trailblazer/cells-erb
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
  export PACKAGE_VERSION=${1:-v0.1.0}
else
  export PACKAGE_VERSION=$1
fi
if [ -d "cells-erb" ] ; then
  rm -rf cells-erb
fi

yum install git ruby ruby-devel -y
gem install bundle

git clone https://github.com/trailblazer/cells-erb
cd cells-erb
git checkout $PACKAGE_VERSION
ret=$?
if [ $ret -eq 0 ] ; then
 echo "$PACKAGE_VERSION found to checkout "
else
 echo "$PACKAGE_VERSION not found "
 exit
fi

#Observed Traceback call error and is in parity with Intel
# /usr/local/rvm/gems/ruby-2.7.2/gems/activesupport-4.2.11.3/lib/active_support/core_ext/object/duplicable.rb:111:in `<class:BigDecimal>': undefined method `new' for BigDecimal:Class (NoMethodError)
# rake aborted!
# Command failed with status (1): [ruby -w -I"lib:test" /usr/local/rvm/gems/ruby-2.7.2/gems/rake-13.0.6/lib/rake/rake_test_loader.rb "test/erb_test.rb" ]

#Build and test

export BUNDLE_GEMFILE=$PWD/Gemfile

which bundle || gem install bundler
gem update bundler

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


