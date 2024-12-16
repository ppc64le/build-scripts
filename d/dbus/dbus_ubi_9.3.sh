#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : dbus
# Version          : 1.13.16
# Source repo      : http://dbus.freedesktop.org/releases/dbus/
# Tested on        : UBI:9.3
# Language         : Python
# Travis-Check     : True
# Script License   : General Public License version 2 or BSD
# Maintainer       : Rakshith R <rakshith.r5@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------- 

PACKAGE_NAME=dbus
PACKAGE_VERSION=${1:-1.13.16}
PACKAGE_URL=http://dbus.freedesktop.org/releases/dbus/

dnf update -y
dnf install -y wget xz glibc-devel dbus-devel pkgconfig automake autoconf libtool cairo-devel libxml2-devel gperf gcc-c++ make expat-devel
wget $PACKAGE_URL/$PACKAGE_NAME-$PACKAGE_VERSION.tar.xz
tar -xf $PACKAGE_NAME-$PACKAGE_VERSION.tar.xz
cd $PACKAGE_NAME-$PACKAGE_VERSION
./configure --prefix=$HOME/.local
make
make install
installed_version=$(dbus-daemon --version | grep -oP '\d+\.\d+\.\d+')

if [ "$installed_version" == "$PACKAGE_VERSION" ]; then
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | dbus | Pass |  Both_Install_and_Test_Success"
    exit 0
else
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | dbus | Fail |  Install_Fails"
    exit 1
fi
