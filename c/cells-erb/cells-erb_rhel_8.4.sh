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

set -e

if [ -z "$1" ]; then
  export PACKAGE_VERSION=${1:-v0.1.0}
else
  export PACKAGE_VERSION=$1
fi
if [ -d "cells-erb" ] ; then
  rm -rf cells-erb
fi

yum install -y git ruby procps yum-utils wget

yum-config-manager --add-repo http://mirror.centos.org/centos/8/AppStream/ppc64le/os/ && yum-config-manager --add-repo http://mirror.centos.org/centos/8/PowerTools/ppc64le/os/ && yum-config-manager --add-repo http://mirror.centos.org/centos/8/BaseOS/ppc64le/os/ && yum-config-manager --add-repo http://mirror.centos.org/centos/8/virt/ppc64le/ovirt-44/

wget https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official && mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/. && rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official

wget https://www.centos.org/keys/RPM-GPG-KEY-CentOS-SIG-Virtualization && mv RPM-GPG-KEY-CentOS-SIG-Virtualization /etc/pki/rpm-gpg/. && rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Virtualization

gem install bundle 
gem install rake 
curl -sSL https://rvm.io/mpapis.asc | gpg2 --import - 
curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import - 
curl -L https://get.rvm.io | bash -s stable 
source /etc/profile.d/rvm.sh
rvm install ruby-2.7
gem install bundler:1.17.3
gem install kramdown-parser-gfm

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


