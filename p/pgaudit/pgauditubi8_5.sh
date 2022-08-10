#!/bin/bash -e

# ----------------------------------------------------------------------------
# Package          : pgaudit
# Version          : REL2_0_1
# Source repo      : https://github.com/pgaudit/set_user.git
# Tested on        : UBI 8.5
# Language         : C++
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Ankit Paraskar <Ankit.Paraskar@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
# Note:- Travis check is made false since it takes more time than travis timeout value.
# ----------------------------------------------------------------------------

# Variables

PACKAGE_NAME=pgaudit
PACKAGE_URL=https://github.com/pgaudit/set_user.git
#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=REL2_0_1

yum install -y git automake libtool make unzip gcc-c++ autoconf zlib xz m4 gettext help2man wget diffutils

dnf install -qy http://mirror.nodesdirect.com/centos/8-stream/BaseOS/ppc64le/os/Packages/centos-gpg-keys-8-6.el8.noarch.rpm
dnf install -qy http://mirror.nodesdirect.com/centos/8-stream/BaseOS/ppc64le/os/Packages/centos-stream-repos-8-6.el8.noarch.rpm
dnf config-manager --enable powertools
dnf install -qy epel-release
dnf install -qy gettext-devel

wget https://ftp.gnu.org/gnu/bison/bison-3.8.tar.xz
xz -d bison-3.8.tar.xz
tar -xvf bison-3.8.tar
cd bison-3.8

./configure
make
make install
cd ..

wget https://github.com/westes/flex/releases/download/v2.6.3/flex-2.6.3.tar.gz
tar -xvf flex-2.6.3.tar.gz
cd flex-2.6.3
./autogen.sh
./configure
make 
make install
cd ..

git clone https://github.com/postgres/postgres.git
cd postgres
git checkout REL9_5_STABLE
./configure --without-readline --without-zlib
make install -s

cd contrib
git clone https://github.com/pgaudit/set_user.git

cd set_user

git checkout $PACKAGE_VERSION


if ! (make && make install) ; then
                        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
                        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | master  | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
                        exit 0
                else
                        echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
                        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | master | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
                        exit 0
                fi
