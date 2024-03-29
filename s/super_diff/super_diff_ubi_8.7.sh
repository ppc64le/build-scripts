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

PACKAGE_NAME=super_diff
PACKAGE_VERSION=${1:-v0.11.0}
PACKAGE_URL=https://github.com/mcmire/super_diff.git

yum install -y git procps yum-utils wget xz
yum install sudo -y
yum install -y gcc openssl-devel libyaml-devel libffi-devel zlib-devel  ncurses-devel libxml2-devel libxslt-devel zlib-devel libxml2

curl https://raw.githubusercontent.com/rvm/rvm/master/binscripts/rvm-installer | bash
source /etc/profile.d/rvm.sh
export RUBY_VERSION=${RUBY_VERSION:-3.2.1}

dnf install -qy http://mirror.nodesdirect.com/centos/8-stream/BaseOS/ppc64le/os/Packages/centos-gpg-keys-8-6.el8.noarch.rpm
dnf install -qy http://mirror.nodesdirect.com/centos/8-stream/BaseOS/ppc64le/os/Packages/centos-stream-repos-8-6.el8.noarch.rpm
rvm install "$RUBY_VERSION"
ruby --version

gem install bundle
gem install rake
gem install bundler
gem install nokogiri
gem install rspec
gem install zeus
gem install kramdown-parser-gfm


git clone ${PACKAGE_URL} 
cd ${PACKAGE_NAME}
git checkout ${PACKAGE_VERSION}

export BUNDLE_GEMFILE=gemfiles/rails_7_0_rspec_lt_3_10.gemfile

if ! bundle install ;  then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! bundle exec rake --trace ; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
