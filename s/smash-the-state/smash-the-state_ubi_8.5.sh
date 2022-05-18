#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package               : smash-the-state
# Version               : v1.3.0
# Source repo           : https://github.com/IBM-Cloud/smash-the-state.git
# Tested on             : UBI 8.5
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

export PACKAGE_NAME=smash-the-state
export PACKAGE_URL=https://github.com/IBM-Cloud/smash-the-state.git

if [ -z "$1" ]; then
  export PACKAGE_VERSION=v1.3.0
else
  export PACKAGE_VERSION=$1
fi
if [ -d "${PACKAGE_NAME}" ] ; then
  rm -rf ${PACKAGE_NAME}
fi


yum install -y git ruby procps yum-utils wget

yum-config-manager --add-repo http://mirror.centos.org/centos/8-stream/AppStream/ppc64le/os/ && yum-config-manager --add-repo http://mirror.centos.org/centos/8-stream/PowerTools/ppc64le/os/ && yum-config-manager --add-repo http://mirror.centos.org/centos/8-stream/BaseOS/ppc64le/os/ && yum-config-manager --add-repo http://mirror.centos.org/centos/8-stream/virt/ppc64le/ovirt-44/

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

git clone ${PACKAGE_URL} ${PACKAGE_NAME}
cd ${PACKAGE_NAME}
git checkout ${PACKAGE_VERSION}
ret=$?
if [ $ret -eq 0 ] ; then
  echo "Version $PACKAGE_VERSION found to checkout "
else
  echo "Version $PACKAGE_VERSION not found "
  exit
fi

bundle config set --local disable_checksum_validation true
bundle install
ret=$?
bundle config set --local disable_checksum_validation false
if [ $ret -ne 0 ] ; then
  echo "Build failed "
else
  bundle exec rspec
  ret=$?
  if [ $ret -ne 0 ] ; then
    echo "Test failed "
  else
    echo "Build & Test Successful "
  fi
fi
