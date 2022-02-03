#!/bin/bash -e

# ----------------------------------------------------------------------------
#
# Package               : byebug
# Version               : v10.0.1
# Source repo           : https://github.com/deivid-rodriguez/byebug
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
  export PACKAGE_VERSION=${1:-v10.0.1}
else
  export PACKAGE_VERSION=$1
fi
if [ -d "byebug" ] ; then
  rm -rf byebug
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

git clone https://github.com/deivid-rodriguez/byebug
cd byebug
git checkout $PACKAGE_VERSION
ret=$?
if [ $ret -eq 0 ] ; then
 echo "$PACKAGE_VERSION found to checkout "
else
 echo "$PACKAGE_VERSION not found "
 exit
fi

#Observed 7 test failures and all are in parity with intel
# Failure:
#Byebug::ThreadTest#test_thread_list_shows_all_available_threads [/root/rubybuildscripts/byebug/test/support/matchers.rb:29]:
#Byebug::MinitestRunnerTest#test_with_seed_option,#test_per_test, 
#test_per_test_class,#test_runs,#test_with_verbose_option,#test_combinations[/root/rubybuildscripts/byebug/test/minitest_runner_test.rb:60]:
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


