#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : httpd
# Version          : 2.4.58
# Source repo      : https://github.com/apache/httpd
# Tested on        : UBI 8.7
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
set -e

PACKAGE_NAME=httpd
PACKAGE_VERSION=${1:-2.4.58}
PACKAGE_URL=https://github.com/apache/httpd
APR_VERSION="1.7.4"
APR_UTIL_VERSION="1.6.3"

wrkdir=`pwd`

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

yum update -y
yum install git gcc make python38 libtool autoconf make pcre pcre-devel libxml2 libxml2-devel expat-devel which wget tar -y

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

cd $wrkdir/$PACKAGE_NAME/srclib
git clone https://github.com/apache/apr.git
cd $wrkdir/$PACKAGE_NAME/srclib/apr  && git checkout $APR_VERSION

cd $wrkdir/$PACKAGE_NAME/srclib
git clone https://github.com/apache/apr-util.git
cd $wrkdir/$PACKAGE_NAME/srclib/apr-util && git checkout $APR_UTIL_VERSION


cd $wrkdir/$PACKAGE_NAME
./buildconf
./configure --with-included-apr
make

if ! make install ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

sed -i '52s/Listen 80/Listen 8081/' /usr/local/apache2/conf/httpd.conf
sed -i '197s/#ServerName www.example.com:80/ServerName localhost/' /usr/local/apache2/conf/httpd.conf
/usr/local/apache2/bin/apachectl start


if ! curl localhost:8081 ; then
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