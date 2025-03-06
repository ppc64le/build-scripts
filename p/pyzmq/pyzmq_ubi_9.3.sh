#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : pyzmq
# Version          : 26.2.1
# Source repo      : https://github.com/zeromq/pyzmq.git
# Tested on        : UBI:9.3
# Language         : Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vinod.K1 <Vinod.K1@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

# Variables
PACKAGE_NAME=pyzmq
PACKAGE_VERSION=${1:-v26.2.1}
PACKAGE_URL=https://github.com/zeromq/pyzmq.git
PACKAGE_DIR=./pyzmq

# Install dependencies
yum install -y git gcc gcc-c++ cmake make wget openssl-devel bzip2-devel libffi-devel zlib-devel python3-devel python3-pip

#Install zeromq-devel
wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/.
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official
dnf install --nodocs -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

git clone https://github.com/zeromq/libzmq.git
cd libzmq
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local -DBUILD_SHARED=ON
make -j$(nproc)
make install
export LD_LIBRARY_PATH=/usr/local/lib64:$LD_LIBRARY_PATH
ldconfig
cd ../..

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

export PKG_CONFIG_PATH=/usr/local/lib64/pkgconfig
export LIBRARY_PATH=/usr/local/lib64
export LD_LIBRARY_PATH=/usr/local/lib64
export CPATH=/usr/local/include
export CMAKE_PREFIX_PATH=/usr/local

mkdir -p zmq/libs
cp /usr/local/lib64/libzmq.so* zmq/libs/
# install necessary Python packages
#pip install -r test-requirements.txt
pip install setuptools wheel cython cffi pytest tornado pytest-asyncio pytest-timeout scikit_build_core build ninja

#install
if ! (pip install .) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi
# Run tests
if ! pytest -v --timeout=60 --capture=no -p no:warnings; then
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
