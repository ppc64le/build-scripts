#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : onnxruntime
# Version          : v1.21.0
# Source repo      : https://github.com/microsoft/onnxruntime
# Tested on		   : UBI:9.3
# Language         : Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Ramnath Nayak <Ramnath.Nayak@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=onnxruntime
# Using commit from main branch as v1.21.0 is yet to be tagged 
# and MMA symbols aren't avaivable in v1.20.1.
PACKAGE_VERSION=${1:-v1.21.0}
PACKAGE_COMMIT=d1fb58b0f2be7a8541bfa73f8cbb6b9eba05fb6b
PACKAGE_URL=https://github.com/microsoft/onnxruntime
PACKAGE_DIR="onnxruntime"
CURRENT_DIR=$(pwd)

yum install -y gcc-c++ make libtool cmake git wget xz zlib-devel openssl-devel bzip2-devel libffi-devel libevent-devel gcc-gfortran patch python python-devel ninja-build

dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os/
wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/.
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official

dnf install --nodocs -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

# install core dependencies
yum install -y gcc-toolset-13 gcc-toolset-13-binutils gcc-toolset-13-binutils-devel gcc-toolset-13-gcc-c++ openblas openblas-devel abseil-cpp abseil-cpp-devel
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export SITE_PACKAGE_PATH="/lib/python3.12/site-packages"
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

#Installing protobuf-c
git clone https://github.com/protocolbuffers/protobuf.git
cd protobuf
git checkout v3.20.2
git submodule update --init --recursive
mkdir build_source && cd build_source
cmake ../cmake -Dprotobuf_BUILD_SHARED_LIBS=OFF -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_SYSCONFDIR=/etc -DCMAKE_POSITION_INDEPENDENT_CODE=ON -Dprotobuf_BUILD_TESTS=OFF -DCMAKE_BUILD_TYPE=Release
echo "Building..."
make -j$(nproc)
echo "Installing..."
make install
cd ../..

pip install --upgrade pip setuptools wheel ninja packaging
pip install cmake numpy==2.0.2 onnx==1.17.0 nbval pythran scipy cython

#Set Paths
export PREFIX=$SITE_PACKAGE_PATH
export PROTO_PREFIX=$PREFIX/libprotobuf/

#Build
git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout $PACKAGE_COMMIT

export CXXFLAGS="-Wno-stringop-overflow"
export CFLAGS="-Wno-stringop-overflow"

#Build and test
if ! (./build.sh \
			--cmake_extra_defines "onnxruntime_PREFER_SYSTEM_LIB=ON" Protobuf_PROTOC_EXECUTABLE=$PROTO_PREFIX/bin/protoc Protobuf_INCLUDE_DIR=$PROTO_PREFIX/include onnxruntime_USE_COREML=OFF \
			--cmake_generator Ninja \
			--build_shared_lib \
			--config Release \
			--update \
			--build \
			--skip_submodule_sync \
			--allow_running_as_root \
			--compile_no_warning_as_error \
			--build_wheel) ; then
    echo "------------------$PACKAGE_NAME:install_&_test_both_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi

cp /onnxruntime/build/Linux/Release/dist/* "$CURRENT_DIR"

