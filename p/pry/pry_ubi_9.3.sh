#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package               : pry
# Version               : v0.14.2
# Source repo           : https://github.com/pry/pry.git
# Tested on             : UBI:9.3
# Language              : Ruby
# Ci-Check          : True
# Script License        : Apache License, Version 2.0
# Maintainer            : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer            : This script has been tested in root mode on given
# ==========              platform using the mentioned version of the package.
#                         It may not work as expected with newer versions of the
#                         package and/or distribution. In such case, please
#                         contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=pry
PACKAGE_VERSION=${1:-v0.14.2}
PACKAGE_URL=https://github.com/pry/pry.git

export TERM=xterm-256color
export ROWS=40
export COLUMNS=160

yum install -y make gcc gcc-c++ autoconf automake glibc-headers \
    glibc-devel openssl-devel git procps ncurses-devel m4 \
    redhat-rpm-config xz info libyaml-devel zlib-devel \
    https://rpmfind.net/linux/centos-stream/9-stream/AppStream/ppc64le/os/Packages/bison-3.7.4-5.el9.ppc64le.rpm \
    https://rpmfind.net/linux/centos-stream/9-stream/AppStream/ppc64le/os/Packages/readline-devel-8.1-4.el9.ppc64le.rpm

curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -
curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import -
curl -L https://get.rvm.io | bash -s stable
source /etc/profile.d/rvm.sh

rvm install ruby-3.3.0

gem install bundle

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! bundle install; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! bundle exec rake; then
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
