#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package               : crass
# Version               : v1.0.4
# Source repo           : https://github.com/rgrove/crass
# Tested on             : UBI 8.4
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

export PACKAGE_NAME=crass
export PACKAGE_URL=https://github.com/rgrove/crass

if [ -z "$1" ]; then
  export PACKAGE_VERSION=${1:-v1.0.4}
else
  export PACKAGE_VERSION=$1
fi
if [ -d "crass" ] ; then
  rm -rf crass
fi


yum install git ruby ruby-devel -y
gem install bundle

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

export BUNDLE_GEMFILE=$PWD/Gemfile

ret=$?
if [ $ret -eq 0 ] ; then
 echo "$PACKAGE_VERSION found to checkout "
else
 echo "$PACKAGE_VERSION not found "
 exit
fi

#Build and test

bundle install

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
