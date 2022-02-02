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

git clone ${PACKAGE_URL} ${PACKAGE_NAME}
cd ${PACKAGE_NAME}
git checkout ${PACKAGE_VERSION}
ret=$?
if [ $ret -eq 0 ] ; then
 echo "$PACKAGE_VERSION found to checkout "
else
 echo "$PACKAGE_VERSION not found "
 exit
fi

#Observed one failure:syntax error  and is in parity with Intel
#Failed examples:
#rspec ./spec/method_source/code_helpers_spec.rb[1:6] # MethodSource::CodeHelpers should not raise an error on broken lines: issue = %W/\n343/
#/usr/local/rvm/rubies/ruby-2.7.2/bin/ruby -w -I/usr/local/rvm/gems/ruby-2.7.2/gems/rspec-core-3.10.1/lib:/usr/local/rvm/gems/ruby-2.7.2/gems/rspec-support-3.10.3/lib 
#/usr/local/rvm/gems/ruby-2.7.2/gems/rspec-core-3.10.1/exe/rspec --pattern spec/\*\*\{,/\*/\*\*\}/\*_spec.rb failed

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

