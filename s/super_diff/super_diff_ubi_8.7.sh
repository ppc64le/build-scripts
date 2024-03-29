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

yum -y update
yum install -y git procps ncurses-devel wget m4 redhat-rpm-config xz 


wget https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/bison-3.0.4-10.el8.ppc64le.rpm
wget https://rpmfind.net/linux/centos/8-stream/BaseOS/ppc64le/os/Packages/readline-devel-7.0-10.el8.ppc64le.rpm
rpm -i *.rpm


git clone $REPOSITORY $PKG_NAME-$PKG_VERSION
cd $PKG_NAME-$PKG_VERSION/
git checkout $PKG_VERSION

# setup build environment
sed -i s/sudo//g bin/setup
bin/setup

# install ruby version manager (rvm) and get required ruby version
# link: https://rvm.io/
gpg2 --keyserver keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
curl -sSL https://get.rvm.io | bash -s stable

source /etc/profile.d/rvm.sh
rvm -v

yum install -y libyaml-devel
rvm install "ruby-$(cat .ruby-version)"

gem install bundle

export BUNDLE_GEMFILE=gemfiles/rails_7_0_rspec_lt_3_10.gemfile

# install dependent gems
bundle install



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
