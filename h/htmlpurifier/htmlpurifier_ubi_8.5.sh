#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: htmlpurifier
# Version	: 	v4.13.0
# Source repo	: https://github.com/ezyang/htmlpurifier.git
# Tested on	: UBI 8.5
# Language      : PHP
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: saraswati patra <saraswati.patra@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME=htmlpurifier
PACKAGE_VERSION=${1:-v4.13.0}
PACKAGE_URL=https://github.com/ezyang/htmlpurifier.git
yum update -y --allowerasing --nobest
yum install -y git php php-common php-json php-dom php-zip php-pdo php-mbstring wget yum-utils
#yum-config-manager --add-repo http://mirror.centos.org/centos/8-stream/AppStream/ppc64le/os/ 
#yum-config-manager --add-repo http://mirror.centos.org/centos/8-stream/PowerTools/ppc64le/os/
#yum-config-manager --add-repo http://mirror.centos.org/centos/8-stream/BaseOS/ppc64le/os/

#wget https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official
#mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/. 
#rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official

yum install -y expect

wget https://pear.php.net/go-pear.phar

cat > script.exp <<EOF
set timeout -1
spawn php go-pear.phar
match_max 100000
expect "1-12, 'all' or Enter to continue: "
send -- "\r"
expect eof
EOF

expect -f script.exp

pear install channel://pear.php.net/Net_IDNA2-0.2.0
OS_NAME=`cat /etc/os-release | grep PRETTY_NAME | cut -d '=' -f2 | tr -d '"'`
HOME_DIR=`pwd`

#Check if package exists
if [ -d "$PACKAGE_NAME" ] ; then
  rm -rf $PACKAGE_NAME
  echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Removed existing package if any"
fi
if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
    exit 1
fi
cd "$HOME_DIR"/$PACKAGE_NAME || exit 1
git checkout "$PACKAGE_VERSION"
git clone --depth=50 https://github.com/ezyang/simpletest.git
cp test-settings.travis.php test-settings.php

if ! php tests/index.php; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  install_success"
    exit 1
fi
#All HTML Purifier tests on PHP 7.2.24
#1) Identical expectation [String: xn--fa-hia.de] fails with [String: fass.de] at character 0 with [xn--fa-hia.de] and [fass.de] at [/root/htmlpurifier/tests/HTMLPurifier/AttrDef/URI/HostTest.php line 52]
        #in testIDNA
        #in HTMLPurifier_AttrDef_URI_HostTest
#FAILURES!!!
