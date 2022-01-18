#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package               : topmodel
# Version               : master
# Source repo           : https://github.com/agilastic/topmodel.git
# Tested on             : UBI 8.4
# Language              : Ruby
# Travis-Check          : True
# Script License        : Apache License, Version 2 or later
# Maintainer            : Vikas . <kumar.vikas@in.ibm.com>
#
# Disclaimer            : This script has been tested in root mode on given
# ==========              platform using the mentioned version of the package.
#                         It may not work as expected with newer versions of the
#                         package and/or distribution. In such case, please
#                         contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

if [ -z "$1" ]; then
  export PACKAGE_VERSION=53f07d785e62e85a0f680c126be7cf42aa5fc868
else
  export PACKAGE_VERSION=$1
fi
if [ -d "topmodel" ] ; then
  rm -rf topmodel
fi

yum install -y git ruby procps 
gem install bundle 
gem install rake 
curl -sSL https://rvm.io/mpapis.asc | gpg2 --import - 
curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import - 
curl -L https://get.rvm.io | bash -s stable 
source /etc/profile.d/rvm.sh
rvm install ruby-2.7
gem install bundler:1.17.3
gem install kramdown-parser-gfm

gem install jeweler

git clone https://github.com/agilastic/topmodel.git
cd topmodel
git checkout $PACKAGE_VERSION
ret=$?
if [ $ret -eq 0 ] ; then
  echo "Version $PACKAGE_VERSION found to checkout "
else
  echo "Version $PACKAGE_VERSION not found "
  exit
fi

bundle config set --local disable_checksum_validation true
bundle _1.17.3_ exec rake build
ret=$?
bundle config set --local disable_checksum_validation false
if [ $ret -ne 0 ] ; then
  echo "Build failed "
else
  bundle _1.17.3_ exec rake install
  ret=$?
  if [ $ret -ne 0 ] ; then
    echo "Install failed "
  else
    echo "Build & Install Successful "
  fi
fi
