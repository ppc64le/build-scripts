#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package	: opentelemetry-ruby
# Version	: opentelemetry-sdk-experimental/v0.1.0
# Source repo	: https://github.com/open-telemetry/opentelemetry-ruby.git
# Tested on	: ubi 8.5
# Language      : ruby
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Adilhusain Shaikh <Adilhusain.Shaikh@ibm.com>,,Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME="opentelemetry-ruby"
PACKAGE_VERSION=${1:-"opentelemetry-sdk-experimental/v0.1.0"}
PACKAGE_URL="https://github.com/open-telemetry/opentelemetry-ruby.git"
export RUBY_VERSION=${RUBY_VERSION:-2.7.0}

dnf install -qy http://mirror.nodesdirect.com/centos/8-stream/BaseOS/ppc64le/os/Packages/centos-gpg-keys-8-6.el8.noarch.rpm
dnf install -qy http://mirror.nodesdirect.com/centos/8-stream/BaseOS/ppc64le/os/Packages/centos-stream-repos-8-6.el8.noarch.rpm
dnf install -qy procps git
curl https://raw.githubusercontent.com/rvm/rvm/master/binscripts/rvm-installer | bash
source /etc/profile.d/rvm.sh
rvm install "$RUBY_VERSION"

git clone -q $PACKAGE_URL $PACKAGE_NAME
cd $PACKAGE_NAME
git checkout "$PACKAGE_VERSION"
gem install bundle
bundle install
cd api
bundle install && echo "installation successful for API."
bundle exec rake test && echo "Tests successful for API."
cd ../sdk
bundle add minitest -v 5.15.0
bundle install && echo "Installation successful for SDK..."
bundle exec rake test && echo "Tests successful for SDK"
