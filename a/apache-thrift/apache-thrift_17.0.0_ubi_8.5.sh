#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package          : thrift
# Version          : v0.17.0
# Source repo      : https://github.com/apache/thrift
# Tested on        : UBI 8.5
# Language         : C++,Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Ambuj Kumar <Ambuj.Kumar3@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME=thrift
PACKAGE_VERSION=${1:-v0.17.0}
PACKAGE_URL=https://github.com/apache/thrift
yum install -y git make libtool gcc-c++ libevent-devel zlib-devel openssl-devel python3 python3-devel
yum install -y automake curl wget bzip2-devel bzip2
# Install extra packages from CentOS-8
rpm -ivh https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/bison-3.0.4-10.el8.ppc64le.rpm
rpm -ivh https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/flex-2.6.1-9.el8.ppc64le.rpm

wget http://downloads.sourceforge.net/project/boost/boost/1.56.0/boost_1_56_0.tar.bz2
tar -xvf boost_1_56_0.tar.bz2
export CPLUS_INCLUDE_PATH="$CPLUS_INCLUDE_PATH:/usr/include/python3.6m/"
cd boost_1_56_0
./bootstrap.sh --prefix=/usr/local
./b2 install --prefix=/usr/local --with=all
cd -

# Create symlink for python
ln -sf /usr/bin/python3 /usr/bin/python
HOME_DIR=`pwd`
OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)
if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
        echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
        exit 1
fi
#cp apache-thrift_v17.0.0.patch thrift
cd $HOME_DIR/$PACKAGE_NAME
git checkout $PACKAGE_VERSION
wget https://raw.githubusercontent.com/ppc64le/build-scripts/master/a/apache-thrift/apache-thrift_v17.0.0.patch;
git apply apache-thrift_v17.0.0.patch;
if ! ./bootstrap.sh; then
        echo "------------------$PACKAGE_NAME:bootstrap_fails-------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Bootstrap_Fails"
        exit 1
fi
cd $HOME_DIR/$PACKAGE_NAME
if ! ./configure --with-boost --with-cpp --without-c_glib --without-java --without-kotlin; then
#if ! ./configure; then
        echo "------------------$PACKAGE_NAME:configure_fails-------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Configure_Fails"
        exit 1
fi
cd $HOME_DIR/$PACKAGE_NAME
if ! make; then
        echo "------------------$PACKAGE_NAME:make_fails-------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Make_Fails"
        exit 1
fi
cd $HOME_DIR/$PACKAGE_NAME
if ! make install; then
        echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
        exit 1
fi
cd $HOME_DIR/$PACKAGE_NAME
if ! make -k check; then
        echo "------------------$PACKAGE_NAME:check_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Check_Fails"
        exit 1
fi
if ! make cross ; then
    echo "------------------$PACKAGE_NAME::install_and_Test_fails-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION  | GitHub  | Fail|  Build_and_Test_fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME::install_and_Test_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION  | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi
