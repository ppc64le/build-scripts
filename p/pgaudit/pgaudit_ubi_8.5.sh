#!/bin/bash -e

# ----------------------------------------------------------------------------
# Package          : pgaudit
# Version          : REL_11_STABLE,REL_12_STABLE
# Source repo      : https://github.com/pgaudit/pgaudit
# Tested on        : UBI 8.5
# Language         : C
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
PACKAGE_NAME=pgaudit
PACKAGE_URL=https://github.com/pgaudit/pgaudit
#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=${1:-REL_12_STABLE}

#Dependencies 
 yum install -y git openssl-devel redhat-rpm-config wget automake cmake libtool autoconf-2.69 gcc-c++ make
 dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
 dnf install -y postgresql postgresql12-server postgresql12-devel
 dnf install https://download.postgresql.org/pub/repos/yum/12/redhat/rhel-8-ppc64le/postgresql12-contrib-12.10-1PGDG.rhel8.ppc64le.rpm
 
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

if ! make install USE_PGXS=1 PG_CONFIG=/usr/pgsql-12/bin/pg_config; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! PGUSER=postgres make installcheck USE_PGXS=1 PG_CONFIG=/usr/pgsql-12/bin/pg_config; then
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
