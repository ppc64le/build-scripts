#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : libseccomp
# Version          : v2.5.4
# Source repo      : https://github.com/seccomp/libseccomp
# Tested on        : UBI 8.7
# Language         : C, Python
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

PACKAGE_NAME=libseccomp
PACKAGE_VERSION=${1:-v2.5.4}
PACKAGE_URL=https://github.com/seccomp/libseccomp

wrkdir=`pwd`

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

yum install -y --allowerasing gcc gcc-c++ yum-utils make automake autoconf libtool gdb* binutils rpm-build gettext wget
yum install -y libtool libffi-devel autoconf automake make redhat-rpm-config gcc libffi-devel python3-devel openssl-devel cargo python3-cryptography git sudo

cd $wrkdir
wget http://ftp.gnu.org/pub/gnu/gperf/gperf-3.0.4.tar.gz
tar -xzf gperf-3.0.4.tar.gz
cd $wrkdir/gperf-3.0.4 && ./configure && make && make install
export PATH=/usr/local/bin/:$PATH
gperf --version

cd $wrkdir
git clone git://sourceware.org/git/valgrind.git
cd valgrind/
git checkout VALGRIND_3_18_1
./autogen.sh
./configure
make -j
make install

cd $wrkdir
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

./autogen.sh
./configure

if ! make install ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! make check ; then
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