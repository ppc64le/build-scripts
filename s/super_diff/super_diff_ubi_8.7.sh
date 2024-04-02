#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package       : super_diff
# Version       : v0.11.0
# Source repo   : https://github.com/mcmire/super_diff.git
# Tested on     : UBI 8.7
# Language      : Ruby
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Saddi SaiKumar <Saddi.Saikumar3@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PKG_NAME="super_diff"
PKG_VERSION="${1:-v0.11.0}"
REPOSITORY="https://github.com/mcmire/super_diff.git"

echo "Usage: $0 [r<PKG_VERSION>]"
echo "       PKG_VERSION is an optional paramater whose default value is v0.11.0"

echo "============================================YUM  INSTALL============================================"
# install tools and dependent packages
echo "max_parallel_downloads=$(nproc)" >>/etc/yum.conf
yum -y update 
yum install -y sudo make gcc gcc-c++ autoconf automake glibc-headers glibc-devel openssl-devel git procps ncurses-devel wget m4 redhat-rpm-config xz info libyaml-devel zlib-devel nodejs ruby-devel

# installing bison & readline-devel from rpm, otherwise ruby-3.x installation fails
# wget https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/bison-3.0.4-10.el8.ppc64le.rpm
wget https://rpmfind.net/linux/centos-stream/9-stream/AppStream/ppc64le/os/Packages/bison-3.7.4-5.el9.ppc64le.rpm
# wget https://rpmfind.net/linux/centos/8-stream/BaseOS/ppc64le/os/Packages/readline-devel-7.0-10.el8.ppc64le.rpm
wget https://rpmfind.net/linux/centos-stream/9-stream/AppStream/ppc64le/os/Packages/readline-devel-8.1-4.el9.ppc64le.rpm
rpm -i *.rpm

echo "============================================NVM  INSTALL============================================"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source /root/.bashrc
nvm -v
echo "============================================RVM  INSTALL============================================"
# install ruby version manager (rvm) and get required ruby version
# link: https://rvm.io/
gpg2 --keyserver keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
curl -sSL https://get.rvm.io | bash -s stable

source /etc/profile.d/rvm.sh
rvm -v

echo "============================================ GIT  CLONE ============================================"
# clone, build and test latest version
git clone $REPOSITORY $PKG_NAME-$PKG_VERSION
cd $PKG_NAME-$PKG_VERSION/
git checkout $PKG_VERSION

# setup build environment
#sed -i s/sudo//g bin/setup
source bin/setup

echo "============================================RUBY INSTALL============================================"
# install appropriate ruby version
rvm install "ruby-$(cat .ruby-version)"

gem install bundle

echo "============================================ENV VAR SET============================================"
# BUNDLE_GEMFILE NEEDS TO BE SET BEFORE `bundle install`
export BUNDLE_GEMFILE=gemfiles/rails_7_0_rspec_lt_3_10.gemfile

echo "============================================BNDL INSTALL============================================"
# install dependent gems
bundle install --verbose

# build package
gem build *.gemspec
ret=$?
if [ $ret -ne 0 ]; then
    echo "Build failed "
else
    bundle exec rake
    ret=$?
    if [ $ret -ne 0 ]; then
        echo "Test failed"
    else
        echo "Build & Test Successful "
    fi
fi
