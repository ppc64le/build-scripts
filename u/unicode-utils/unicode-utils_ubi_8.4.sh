# ----------------------------------------------------------------------------
#
# Package               : unicode-utils
# Version               : v1.4.0
# Source repo           : https://github.com/lang/unicode_utils.git
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
#!/bin/bash

set -e

if [ -z "$1" ]; then
  export PACKAGE_VERSION=v1.4.0
else
  export PACKAGE_VERSION=$1
fi
if [ -d "unicode_utils" ] ; then
  rm -rf unicode_utils
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

git clone https://github.com/lang/unicode_utils.git
cd unicode_utils
git checkout $PACKAGE_VERSION
ret=$?
if [ $ret -eq 0 ] ; then
  echo "Version $PACKAGE_VERSION found to checkout "
else
  echo "Version $PACKAGE_VERSION not found "
  exit
fi

bundle config set --local disable_checksum_validation true
bundle _1.17.3_ exec rake gem
ret=$?
bundle config set --local disable_checksum_validation false
if [ $ret -ne 0 ] ; then
  echo "Build failed "
else
  bundle _1.17.3_ exec rake test
  ret=$?
  if [ $ret -ne 0 ] ; then
    echo "Tests failed "
  else
    echo "Build & Tests Successful "
  fi
fi
