#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : orc
# Version       : v2.0.3
# Source repo   : https://github.com/apache/orc
# Tested on     : UBI 9.3
# Language      : c
# Travis-Check  : True
# Script License: Apache License 2.0
# Maintainer    : Stuti Wali <Stuti.Wali@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e 

PACKAGE_NAME=orc
PACKAGE_VERSION=${1:-v2.0.3}
PACKAGE_URL=https://github.com/apache/orc
CURRENT_DIR=$(pwd)
PACKAGE_DIR=orc

echo "------------------------Installing dependencies-------------------"
yum install -y wget
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os/
wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/.
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official

dnf install --nodocs -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

# install core dependencies
yum install -y python python-pip python-devel  gcc-toolset-13 gcc-toolset-13-binutils gcc-toolset-13-binutils-devel gcc-toolset-13-gcc-c++ git make cmake binutils

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH
gcc --version

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

yum install -y snappy-devel libzstd-devel lz4-devel abseil-cpp protobuf
python -m pip install --upgrade pip
pip install ninja setuptools

export CC=$(which gcc)
export CXX=$(which g++)
export GCC=$CC
export GXX=$CXX

#Building abseil-cpp which is dependency for libprotobuf
echo "----------------------------------------------Cloning abseil-cpp--------------------------------------------------------"
git clone https://github.com/abseil/abseil-cpp
cd abseil-cpp
git checkout 20240116.2

mkdir $CURRENT_DIR/abseil-prefix
ABSEIL_PREFIX=$CURRENT_DIR/abseil-prefix
mkdir -p $CURRENT_DIR/local/abseilcpp
abseilcpp=$CURRENT_DIR/local/abseilcpp

mkdir build
cd build

cmake -G Ninja \
    ${CMAKE_ARGS} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=17 \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_INSTALL_PREFIX=${ABSEIL_PREFIX} \
    -DBUILD_SHARED_LIBS=ON \
    -DABSL_PROPAGATE_CXX_STD=ON \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
   ..

cmake --build .
cmake --install .

cd $CURRENT_DIR
cp -r  $ABSEIL_PREFIX/* $abseilcpp/
echo "-------------------------------------Abseil-cpp installed successfully-------------------------------------"

#Building libprotobuf which is dependency for orc

cd $CURRENT_DIR
mkdir -p $CURRENT_DIR/local/libprotobuf
LIBPROTO_INSTALL=$CURRENT_DIR/local/libprotobuf

echo "----------------------------------------------Cloning protobuf--------------------------------------------------------"
git clone https://github.com/protocolbuffers/protobuf
cd protobuf
git checkout v4.25.3
git submodule update --init --recursive
rm -rf ./third_party/googletest | true
rm -rf ./third_party/abseil-cpp | true
cp -r $CURRENT_DIR/abseil-cpp ./third_party/

mkdir build
cd build

cmake -G "Ninja" \
   ${CMAKE_ARGS} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=17 \
    -DCMAKE_C_COMPILER=$CC \
    -DCMAKE_CXX_COMPILER=$CXX \
    -DCMAKE_INSTALL_PREFIX=$LIBPROTO_INSTALL \
    -Dprotobuf_BUILD_TESTS=OFF \
    -Dprotobuf_BUILD_LIBUPB=OFF \
    -Dprotobuf_BUILD_SHARED_LIBS=ON \
    -Dprotobuf_ABSL_PROVIDER="module" \
    -DCMAKE_PREFIX_PATH=$ABSEIL_PREFIX \
    -Dprotobuf_JSONCPP_PROVIDER="package" \
    -Dprotobuf_USE_EXTERNAL_GTEST=OFF \
    ..

cmake --build . --verbose
cmake --install .


cd $CURRENT_DIR
export PATH=$LIBPROTO_INSTALL/bin:$PATH
protoc --version

echo "-------------------------------------libprotobuf installed successfuly-------------------------------------"

export LD_LIBRARY_PATH=$CURRENT_DIR//local/abseilcpp/lib:$LD_LIBRARY_PATH
export CMAKE_PREFIX_PATH=$CURRENT_DIR//local/abseilcpp:$CMAKE_PREFIX_PATH
export PROTOBUF_PREFIX=$CURRENT_DIR//local/libprotobuf/:$PROTOBUF_PREFIX


# clone source repository
cd $CURRENT_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/python-ecosystem/o/orc/pyproject.toml
sed -i "s/{PACKAGE_VERSION}/$(echo $PACKAGE_VERSION | sed 's/^v//')/g" pyproject.toml
echo "--------------------------replaced version in pyproject.toml--------------------------"
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/python-ecosystem/o/orc/orc.patch
git apply orc.patch

mkdir prefix
export PREFIX=$(pwd)/prefix
mkdir build && cd build

export HOST=$(uname)-$(uname -m)

CPPFLAGS="${CPPFLAGS} -Wl,-rpath,$VIRTUAL_ENV_PATH/**/lib"

# in cmake args below we are not building java components by keeping "-DBUILD_JAVA=False" as this package is build time dependency of arrow which need only cpp components of orc not java components. If you want to build java components, then change "-DBUILD_JAVA=False" to "-DBUILD_JAVA=True"
cmake ${CMAKE_ARGS} \
    -DCMAKE_PREFIX_PATH=$PREFIX \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_JAVA=False \
    -DLZ4_HOME=/usr \
    -DZLIB_HOME=/usr \
    -DZSTD_HOME=/usr \
    -DCMAKE_POLICY_DEFAULT_CMP0074=NEW \
    -DProtobuf_ROOT=$PROTOBUF_PREFIX \
    -DPROTOBUF_HOME=$PROTOBUF_PREFIX \
    -DPROTOBUF_EXECUTABLE=$PROTOBUF_PREFIX/bin/protoc \
    -DSNAPPY_HOME=/usr \
    -DBUILD_LIBHDFSPP=NO \
    -DBUILD_CPP_TESTS=ON \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DCMAKE_C_COMPILER=$(type -p ${CC})     \
    -DCMAKE_CXX_COMPILER=$(type -p ${CXX})  \
    -DCMAKE_C_FLAGS="$CFLAGS"  \
    -DCMAKE_CXX_FLAGS="$CXXFLAGS -Wno-unused-parameter" \
    "${_CMAKE_EXTRA_CONFIG[@]}" \
    -GNinja ..

#Build package
if ! (ninja && ninja install) ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

cd ..
mkdir -p local/$PACKAGE_NAME
cp -r prefix/* local/$PACKAGE_NAME

#During wheel creation for this package we need exported cmake-args. Once script get exit, and if we build wheel through wrapper script, then those are not applicable during wheel creation. So we are generating wheel for this package in script itself.
echo "---------------------------------------------------Building the wheel--------------------------------------------------"
pip install --upgrade build setuptools wheel
python -m build --wheel --no-isolation --outdir="$CURRENT_DIR/"

echo "----------------------------------------------Testing pkg-------------------------------------------------------"
cd build
#Test package
if ! (ninja test) ; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
