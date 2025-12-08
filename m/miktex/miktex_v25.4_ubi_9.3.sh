#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package       : miktex
# Version       : 25.4
# Source repo   : https://github.com/MiKTeX/miktex
# Tested on     : UBI 9.3
# Language      : C, C++
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Simran Sirsat <Simran.Sirsat@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

SCRIPT_PACKAGE_VERSION=25.4
PACKAGE_NAME=miktex
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}
PACKAGE_URL=https://github.com/MiKTeX/${PACKAGE_NAME}
BUILD_HOME=$(pwd)
PYTHON_VERSION=3.11.5
CMAKE_VERSION=3.28.1

SCRIPT=$(readlink -f $0)
SCRIPT_DIR=$(dirname $SCRIPT)
SCRIPT_PATH=$(dirname $(realpath $0))
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

# Install required dependencies
yum install -y git wget gcc gcc-c++ diffutils gettext libxslt make openssl-devel bzip2-devel libffi-devel xz zlib-devel openblas-devel 

# Install Centos Repos and Dependencies
wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/.
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os/

# Install Python from source
cd $BUILD_HOME
if [ -z "$(ls -A $BUILD_HOME/Python-${PYTHON_VERSION})" ]; then
    wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz
    tar xzf Python-${PYTHON_VERSION}.tgz
    rm -rf Python-${PYTHON_VERSION}.tgz 
    cd Python-${PYTHON_VERSION}
    ./configure --with-system-ffi --with-computed-gotos --enable-loadable-sqlite-extensions
    make -j ${nproc} 
else
    cd Python-${PYTHON_VERSION}
fi
make altinstall
ln -sf $(which python3.11) /usr/bin/python3
ln -sf $(which pip3.11) /usr/bin/pip3
python3 -V && pip3 -V

# Install cmake
cd $BUILD_HOME
if [ -z "$(ls -A $BUILD_HOME/cmake-${CMAKE_VERSION})" ]; then
    wget -c https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz
    tar -zxvf cmake-${CMAKE_VERSION}.tar.gz
    rm -rf cmake-${CMAKE_VERSION}.tar.gz
    cd cmake-${CMAKE_VERSION}
    ./bootstrap --prefix=/usr/local/cmake --parallel=2 -- -DBUILD_TESTING:BOOL=OFF -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_USE_OPENSSL:BOOL=ON
else
    cd cmake-${CMAKE_VERSION}
fi
make install -j$(nproc)
export PATH=/usr/local/cmake/bin:$PATH
cmake --version

# Clone the repo
cd $BUILD_HOME
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Install dependencies
yum install -y https://rpmfind.net/linux/centos-stream/9-stream/AppStream/ppc64le/os/Packages/bison-3.7.4-5.el9.ppc64le.rpm
yum install -y https://rpmfind.net/linux/centos-stream/9-stream/AppStream/ppc64le/os/Packages/flex-2.6.4-9.el9.ppc64le.rpm

# Install EPEL9 Repo
dnf install --nodocs -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

# Install package dependencies
yum install -y apr-devel apr-util-devel boost-devel bzip2-devel cairo-devel curl-devel fribidi-devel gd-devel gmp-devel hunspell-devel log4cxx log4cxx-devel  uriparser uriparser-devel zziplib-devel cups-devel libmspack libmspack-devel popt popt-devel mpfr-devel
yum install -y https://rpmfind.net/linux/epel/9/Everything/ppc64le/Packages/q/qt6-qt3d-6.6.2-1.el9.ppc64le.rpm
yum install -y https://rpmfind.net/linux/epel/9/Everything/ppc64le/Packages/q/qt6-qt5compat-devel-6.6.2-1.el9.ppc64le.rpm
yum install -y https://rpmfind.net/linux/epel/9/Everything/ppc64le/Packages/q/qt6-qt3d-devel-6.6.2-1.el9.ppc64le.rpm
yum install -y https://rpmfind.net/linux/epel/9/Everything/ppc64le/Packages/q/qt6-qttools-devel-6.6.2-3.el9.ppc64le.rpm

# Build MPFI from source
cd $BUILD_HOME
yum install -y gmp-devel mpfr-devel autoconf automake libtool
git clone https://gitlab.inria.fr/mpfi/mpfi.git
cd mpfi/
autoreconf -v -i
./autogen.sh
./configure
make 
make install 

cd $BUILD_HOME/$PACKAGE_NAME

# Apply Patch 
git apply  --reject --whitespace=fix --ignore-space-change --ignore-whitespace ${SCRIPT_PATH}/${PACKAGE_NAME}_v${SCRIPT_PACKAGE_VERSION}.patch

# Generate cmake binaries
if ! cmake ../$PACKAGE_NAME; then
    echo "------------------$PACKAGE_NAME:cmake_build_failed-------------------------------------------"
    exit 1
fi

# Build the package
if ! make; then
    echo "------------------$PACKAGE_NAME:build_failed-------------------------------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
	exit 1
fi

# Run Tests
if  ! make test; then
    echo "------------------$PACKAGE_NAME:test_fails---------------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Test_Fails"
    exit 2
else
        echo "------------------$PACKAGE_NAME:install_and_test_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Install_and_Test_Success"
	exit 0
fi


