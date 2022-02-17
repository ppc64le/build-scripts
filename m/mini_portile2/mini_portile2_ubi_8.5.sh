#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package               : mini_portile
# Version               : v2.3.0,v2.4.0
# Source repo           : https://github.com/flavorjones/mini_portile
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
  export PACKAGE_VERSION=${1:-v2.3.0}
else
  export PACKAGE_VERSION=$1
fi
if [ -d "mini_portile" ] ; then
  rm -rf mini_portile
fi

yum install -y git ruby procps yum-utils wget

gem install bundle 
gem install rake 
curl -sSL https://rvm.io/mpapis.asc | gpg2 --import - 
curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import - 
curl -L https://get.rvm.io | bash -s stable 
source /etc/profile.d/rvm.sh
rvm install ruby-2.7
gem install bundler:1.17.3
gem install kramdown-parser-gfm

git clone https://github.com/flavorjones/mini_portile
cd mini_portile
git checkout $PACKAGE_VERSION
ret=$?
if [ $ret -eq 0 ] ; then
 echo "$PACKAGE_VERSION found to checkout "
else
 echo "$PACKAGE_VERSION not found "
 exit
fi

#Observed one error:Rake aborted and is in parity with Intel
#  1) Error:
#TestCMake#before_all:
#RuntimeError: Failed to complete configure task
#    /root/rubybuildscripts/mini_portile/lib/mini_portile2/mini_portile.rb:402:in `block in execute'
#    /root/rubybuildscripts/mini_portile/lib/mini_portile2/mini_portile.rb:373:in `chdir'
#    /root/rubybuildscripts/mini_portile/lib/mini_portile2/mini_portile.rb:373:in `execute'

#Build and test

bundle _1.17.3_ install

ret=$?
if [ $ret -ne 0 ] ; then
  echo "Build failed "
else
  bundle _1.17.3_ exec rake
  ret=$?
  if [ $ret -ne 0 ] ; then
    echo "Tests failed "
  else
    echo "Build & unit tests Successful "
  fi
fi


