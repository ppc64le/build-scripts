#!/bin/bash -e

# ----------------------------------------------------------------------------
# Package          : ModSecurity
# Version          : v3.0.3
# Source repo      : https://github.com/SpiderLabs/ModSecurity
# Tested on        : UBI 8.5
# Language         : C++
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Bhagat Singh <Bhagat.singh1@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#   
# ----------------------------------------------------------------------------

# Variables
PACKAGE_NAME=ModSecurity
PACKAGE_URL=https://github.com/SpiderLabs/ModSecurity
#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=${1:-v3.0.3}

#Dependencies 
 yum install -y git pcre-devel wget automake cmake libtool autoconf-2.69 gcc-c++ make
  
 OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

#Check if package exists
if [ -d "$PACKAGE_NAME" ] ; then
      rm -rf $PACKAGE_NAME
  echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Removed existing package if any"  
fi
 
# Cloning the repository from remote to local
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

     git submodule init
     git submodule update
    ./build.sh
    ./configure

if ! make; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! make check; then
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