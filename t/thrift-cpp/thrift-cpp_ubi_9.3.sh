#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : thrift-cpp
# Version       : 0.21.0
# Source repo   : https://github.com/apache/thrift
# Tested on     : UBI:9.3
# Language      : Python, C++
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Haritha Nagothu <haritha.nagothu2@ibm.com>
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

yum install -y wget
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os/
dnf install --nodocs -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/.
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official

PACKAGE_NAME=thrift-cpp
PACKAGE_DIR=thrift
PACKAGE_VERSION=${1:-0.21.0}
PACKAGE_URL=https://github.com/apache/thrift

yum install -y python python-pip python-devel git make  python-devel  openssl-devel cmake zlib-devel libjpeg-devel gcc-toolset-13 cmake libevent libtool boost-devel.ppc64le flex bison

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH

pip install ninja setuptools

# clone source repository
git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION
Source_DIR=$(pwd)

mkdir prefix
export PREFIX=$Source_DIR/prefix

export BOOST_ROOT=/usr
export ZLIB_ROOT=/usr
export LIBEVENT_ROOT=/usr

export OPENSSL_ROOT=/usr
export OPENSSL_ROOT_DIR=/usr

./bootstrap.sh
./configure --prefix=$PREFIX \
    --with-python=no \
    --with-py3=no \
    --with-ruby=no \
    --with-java=no \
    --with-kotlin=no \
    --with-erlang=no \
    --with-nodejs=no \
    --with-c_glib=no \
    --with-haxe=no \
    --with-rs=no \
    --with-cpp=yes \
    --with-PACKAGE=yes \
    --with-zlib=$ZLIB_ROOT \
    --with-libevent=$LIBEVENT_ROOT \
    --with-boost=$BOOST_ROOT \
    --with-openssl=$OPENSSL_ROOT \
    --enable-tests=no \
    --enable-tutorial=no 

make -j$(nproc)
make install

cd $Source_DIR
mkdir -p local/thriftcpp

cp -r $PREFIX/* /thrift/local/thriftcpp/

#pyproject.toml
wget https://raw.githubusercontent.com/Harithanagothu2/build-scripts/cb425f8b17c94301b8b9b457c2b85752241c1d0f/t/thrift-cpp/pyproject.toml

#test
make -k check

if ! pip install . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:Install_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_Success"
    exit 0
fi
