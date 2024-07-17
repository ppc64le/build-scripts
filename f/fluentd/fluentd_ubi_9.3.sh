#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: fluentd
# Version	: v1.17.0
# Source repo	: https://github.com/fluent/fluentd.git
# Tested on	: UBI: 9.3
# Language      : Ruby
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Pooja Shah <Pooja.Shah4@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=fluentd
PACKAGE_VERSION=${1:-v1.17.0}
PACKAGE_URL=https://github.com/fluent/fluentd.git
HOME_DIR=$PWD

yum install -y yum-utils openssl-devel git gcc make wget tar libyaml-devel gdbm zlib-devel

#Adding repo to install flex, bison and readline
yum-config-manager --add-repo http://rpmfind.net/linux/centos-stream/9-stream/AppStream/ppc64le/os/
yum-config-manager --add-repo http://rpmfind.net/linux/centos-stream/9-stream/BaseOS/ppc64le/os/
wget https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/.
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official

yum install -y flex bison readline-devel

# Build Ruby v3.3.2
cd $HOME_DIR
wget http://cache.ruby-lang.org/pub/ruby/3.2/ruby-3.2.2.tar.gz
tar zxf ruby-3.2.2.tar.gz
cd ruby-3.2.2
./configure
make
make install
export PATH=/usr/local/bin:$PATH
ruby -v

# Setup the GEM_HOME and PATH environment
export GEM_HOME=${HOME}/.gem/ruby
export PATH=${HOME}/.gem/ruby/bin:$PATH

# Cloning fluentd
cd $HOME_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

gem install bundler

if ! bundle install --path vendor/bundle; then
    echo "Install Fails"
    exit 1
fi

if ! bundle exec rake test TEST=test/test_*.rb; then
    echo "Test Fails"
    exit 2
else
    echo "Install & Test Success"
    exit 0
fi