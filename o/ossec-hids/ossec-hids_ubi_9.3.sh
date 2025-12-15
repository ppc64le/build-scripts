#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : ossec-hids
# Version          : 3.7.0
# Source repo      : https://github.com/ossec/ossec-hids
# Tested on        : UBI: 9.3
# Language         : C
# Ci-Check     : True
# Script License   : GNU General Public License v3.0
# Maintainer       : Abhishek Dwivedi <Abhishek.Dwivedi6@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=ossec-hids
PACKAGE_VERSION=${1:-3.7.0}
PACKAGE_URL=https://github.com/ossec/ossec-hids

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

yum install -y git make gcc gcc-c++ openssl openssl-devel pcre2 pcre2-devel systemd-devel zlib-devel
yum install -y curl autoconf automake libtool pkg-config --skip-broken

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

(cd src/ && make TARGET=server build)

if ! (cd src/ && make TARGET=server install) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

sed -i 's:<email_notification>yes</email_notification>:<email_notification>no</email_notification>:g' /var/ossec/etc/ossec.conf
#replace yes with no from "<email_notification>yes</email_notification>"


if ! /var/ossec/bin/ossec-control start ; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi