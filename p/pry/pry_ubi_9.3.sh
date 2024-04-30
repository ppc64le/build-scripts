#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package               : pry
# Version               : v0.14.2
# Source repo           : https://github.com/pry/pry.git
# Tested on             : UBI 9.3
# Language              : Ruby
# Travis-Check          : True
# Script License        : MIT License
# Maintainer            : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer            : This script has been tested in root mode on given
# ==========              platform using the mentioned version of the package.
#                         It may not work as expected with newer versions of the
#                         package and/or distribution. In such case, please
#                         contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

export PACKAGE_NAME=pry
export PACKAGE_URL=https://github.com/pry/pry.git

if [ -z "$1" ]; then
    export PACKAGE_VERSION=v0.14.2
else
    export PACKAGE_VERSION=$1
fi
if [ -d "${PACKAGE_NAME}" ]; then
    rm -rf ${PACKAGE_NAME}
fi

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

git clone ${PACKAGE_URL} ${PACKAGE_NAME}
cd ${PACKAGE_NAME}
git checkout ${PACKAGE_VERSION}
ret=$?
if [ $ret -eq 0 ]; then
    echo "Version $PACKAGE_VERSION found to checkout "
else
    echo "Version $PACKAGE_VERSION not found "
    exit
fi

bundle install
ret=$?
if [ $ret -ne 0 ]; then
    echo "Build failed "
else
    export TERM=xterm-256color
    export ROWS=40
    export COLUMNS=160
    bundle exec rake
    ret=$?
    if [ $ret -ne 0 ]; then
        echo "Test failed "
    else
        echo "Build & Test Successful "
    fi
fi

