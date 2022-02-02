#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package               : method_source
# Version               : v0.8.2,v0.9.0,v1.0.0
# Source repo           : https://github.com/banister/method_source
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

export PACKAGE_NAME=method_source
export PACKAGE_URL=https://github.com/banister/method_source

if [ -z "$1" ]; then
  export PACKAGE_VERSION=${1:-v1.0.0}
else
  export PACKAGE_VERSION=$1
fi
if [ -d "${method_source}" ] ; then
  rm -rf ${method_source}
fi


yum install git ruby ruby-devel -y
gem install bundle

git clone ${PACKAGE_URL} ${PACKAGE_NAME}
cd ${PACKAGE_NAME}
git checkout ${PACKAGE_VERSION}

export BUNDLE_GEMFILE=$PWD/Gemfile
which bundle || gem install bundler
gem update bundler

ret=$?
if [ $ret -eq 0 ] ; then
 echo "$PACKAGE_VERSION found to checkout "
else
 echo "$PACKAGE_VERSION not found "
 exit
fi

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

