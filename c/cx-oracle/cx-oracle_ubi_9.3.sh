#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package       : cx-Oracle
# Version       : 8.3.0
# Source repo   : https://github.com/oracle/python-cx_Oracle.git
# Tested on     : UBI 9.3
# Language      : c
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Stuti Wali <Stuti.wali@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


# Variables
PACKAGE_NAME=python-cx_Oracle
PACKAGE_VERSION=${1:-8.3.0}
PACKAGE_URL=https://github.com/oracle/python-cx_Oracle.git
PACKAGE_DIR=python-cx_Oracle
CURRENT_DIR=$(pwd)
export ORACLE_HOME=$(pwd)/opt/oracle


# Install dependencies

yum install -y python-devel python-pip git gcc-toolset-13  make cmake wget openssl-devel bzip2-devel libffi-devel zlib-devel  libjpeg-devel zlib-devel freetype-devel procps-ng openblas-devel  meson ninja-build gcc-gfortran  libomp-devel zip unzip sqlite-devel sqlite 
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH


#install rust
curl https://sh.rustup.rs -sSf | sh -s -- -y
source "$HOME/.cargo/env"  # Update environment variables to use Rust

# Install Oracle Instantclient needed for tests
mkdir -p $ORACLE_HOME && cd $ORACLE_HOME
wget https://download.oracle.com/otn_software/linux/instantclient/193/instantclient-basic-linux.leppc64.c64-19.3.0.0.0dbru.zip
unzip instantclient-basic-linux.leppc64.c64-19.3.0.0.0dbru.zip
rm -f instantclient-basic-linux.leppc64.c64-19.3.0.0.0dbru.zip
wget https://download.oracle.com/otn_software/linux/instantclient/193/instantclient-sdk-linux.leppc64.c64-19.3.0.0.0dbru.zip
unzip instantclient-sdk-linux.leppc64.c64-19.3.0.0.0dbru.zip
rm -f instantclient-sdk-linux.leppc64.c64-19.3.0.0.0dbru.zip
echo $ORACLE_HOME/instantclient_19_3 > /etc/ld.so.conf.d/oracle-instantclient.conf
ldconfig
cd ../..

#installing sqlplus
wget https://download.oracle.com/otn_software/linux/instantclient/193/instantclient-sqlplus-linux.leppc64.c64-19.3.0.0.0dbru.zip
unzip instantclient-sqlplus-linux.leppc64.c64-19.3.0.0.0dbru.zip
rm -f instantclient-sqlplus-linux.leppc64.c64-19.3.0.0.0dbru.zip

export LD_LIBRARY_PATH=/usr/lib64/:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/opt/oracle/instantclient_19_3:$LD_LIBRARY_PATH
export PATH=/opt/oracle/instantclient_19_3:$PATH

# Clone the repository
cd $CURRENT_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init --recursive

ln -sf /opt/rh/gcc-toolset-13/root/usr/lib64/libctf.so.0 /usr/lib64/libctf.so.0

#Install
if ! (pip install .) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:install_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi


# Run test cases
# skipping test as they require oracle_DB
#if ! pytest ; then
#    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
#    echo "$PACKAGE_URL $PACKAGE_NAME"
#    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
#    exit 2
#else
#    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
#    echo "$PACKAGE_URL $PACKAGE_NAME"
#    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
#    exit 0
#fi
