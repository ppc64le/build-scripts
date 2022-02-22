#!/bin/bash -e
#-----------------------------------------------------------------------------
#
# package       : pgbadger
# Version       : v11.1, v11.2, v11.3
# Source repo   : https://github.com/darold/pgbadger.git     
# Tested on     : UBI 8.5
# Script License: Apache License, Version 2 or later
# Maintainer    : Saraswati Patra <saraswati.patra@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintaine" of this script.
#
# ---------------------------------------------------------------------------- 
PACKAGE_NAME=pgbadger
#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=${1:-v11.1}
PACKAGE_URL=https://github.com/darold/pgbadger.git 

# Update Source
yum update -y

# gcc dev tools
#yum groupinstall 'Development Tools' -y

# install perl
yum install perl -y

# install git
yum install git -y
OS_NAME=`cat /etc/os-release | grep PRETTY_NAME | cut -d '=' -f2 | tr -d '"'`
HOME_DIR=`pwd`

if [ -d "$PACKAGE_NAME" ] ; then
  rm -rf $PACKAGE_NAME
  echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Removed existing package if any"  
 
fi

git clone https://github.com/darold/pgbadger.git
cd pgbadger/
perl Makefile.PL
if ! make; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

cd "$HOME_DIR"/$PACKAGE_NAME || exit 1
if ! make install && make test; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
