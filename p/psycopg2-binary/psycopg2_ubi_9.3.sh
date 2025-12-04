#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : psycopg2-binary
# Version          : 2.9.10
# Source repo      : https://github.com/psycopg/psycopg2
# Tested on        : UBI:9.3
# Language         : C,Python
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Ramnath Nayak <Ramnath.Nayak@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=psycopg2-binary
PACKAGE_VERSION=${1:-2.9.10}
PACKAGE_URL=https://github.com/psycopg/psycopg2
PACKAGE_DIR=psycopg2

CURRENT_DIR=${PWD}

yum install -y git make wget libpq-devel postgresql python3 python3-devel python3-pip gcc-toolset-13 gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc

export GCC_TOOLSET_PATH=/opt/rh/gcc-toolset-13/root/usr
export PATH=$GCC_TOOLSET_PATH/bin:$PATH

git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION

pip install pytest locket numpy toolz pandas blosc pyzmq


#Build package
if ! pip install . ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#Testing is skipped as it needs to setup postgreSQL database.
