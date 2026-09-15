#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : thrift-cpp
# Version       : 0.24.0
# Source repo   : https://github.com/apache/thrift
# Tested on     : UBI:10.2
# Language      : Python, C++
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Nayana Thorat <Nayana.Thorat1@ibm.com>
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME=thrift-cpp
PACKAGE_DIR=thrift
PACKAGE_VERSION=${1:-0.24.0}
PACKAGE_URL=https://github.com/apache/thrift

yum install -y python3.14 python3.14-pip git make cmake zlib-devel libjpeg-devel gcc-toolset-15 libevent libtool wget perl-Unicode-Normalize openssl-devel
python3.14 -m pip install ninja setuptools

export PATH=/opt/rh/gcc-toolset-15/root/usr/bin:$PATH
SCRIPT_DIR=$(pwd)
echo $SCRIPT_DIR

echo "-----------flex installing------------------"
wget https://github.com/westes/flex/releases/download/v2.6.4/flex-2.6.4.tar.gz
tar -xvf flex-2.6.4.tar.gz
cd flex-2.6.4
./configure --prefix=/usr
make -j$(nproc)
make install
cd $SCRIPT_DIR

echo "-----------texinfo installing------------------"
wget https://ftp.gnu.org/gnu/texinfo/texinfo-7.2.tar.gz
tar -xzf texinfo-7.2.tar.gz
cd texinfo-7.2
./configure --prefix=/usr/local
make -j"$(nproc)"
make install
cd $SCRIPT_DIR

echo "-------bison installing----------------------"
wget https://ftp.gnu.org/gnu/bison/bison-3.8.2.tar.gz
tar -xvf bison-3.8.2.tar.gz
cd bison-3.8.2
echo "Configuring bison installation..."
./configure --prefix=/usr/local
echo "Compiling the source code bison..."
make -j$(nproc)
echo "Installing bison..."
make install
cd $SCRIPT_DIR

echo "-------boost installing----------------------"

git clone -b boost-1.81.0 https://github.com/boostorg/boost
cd boost
git submodule update --init

mkdir Boost_prefix
export BOOST_PREFIX=$(pwd)/Boost_prefix

INCLUDE_PATH="${BOOST_PREFIX}/include"
LIBRARY_PATH="${BOOST_PREFIX}/lib"

export CC=$(which gcc)
export CXX=$(which g++)
export target_platform=$(uname)-$(uname -m)
CXXFLAGS="${CXXFLAGS} -fPIC"
TOOLSET=gcc

 # http://www.boost.org/build/doc/html/bbv2/tasks/crosscompile.html
cat <<EOF > tools/build/example/site-config.jam
using ${TOOLSET} : : ${CXX} ;
EOF

LINKFLAGS="${LINKFLAGS} -L${LIBRARY_PATH}"

CXXFLAGS="$(echo ${CXXFLAGS} | sed 's/ -march=[^ ]*//g' | sed 's/ -mcpu=[^ ]*//g' |sed 's/ -mtune=[^ ]*//g')" \
CFLAGS="$(echo ${CFLAGS} | sed 's/ -march=[^ ]*//g' | sed 's/ -mcpu=[^ ]*//g' |sed 's/ -mtune=[^ ]*//g')" \
    CXX=${CXX_FOR_BUILD:-${CXX}} CC=${CC_FOR_BUILD:-${CC}} ./bootstrap.sh \
    --prefix="${BOOST_PREFIX}" \
    --without-libraries=python \
    --with-toolset=${TOOLSET} \
    --with-icu="${BOOST_PREFIX}" || (cat bootstrap.log; exit 1)

ADDRESS_MODEL=64
ARCHITECTURE="power"
ABI="sysv"
BINARY_FORMAT="elf"

export CPU_COUNT=$(nproc)

./b2 -q \
    variant=release \
    address-model="${ADDRESS_MODEL}" \
    architecture="${ARCHITECTURE}" \
    binary-format="${BINARY_FORMAT}" \
    abi="${ABI}" \
    debug-symbols=off \
    threading=multi \
    runtime-link=shared \
    link=shared \
    toolset=${TOOLSET} \
    include="${INCLUDE_PATH}" \
    cxxflags="${CXXFLAGS} -Wno-deprecated-declarations" \
    linkflags="${LINKFLAGS}" \
    --layout=system \
    -j"${CPU_COUNT}" \
    install

rm "${BOOST_PREFIX}/include/boost/python.hpp"
rm -r "${BOOST_PREFIX}/include/boost/python"


cd $SCRIPT_DIR
echo "------------------- boost installed-------------------"

echo "------------------- thrift installing-------------------"
# clone source repository
git clone $PACKAGE_URL
cd thrift
git checkout v$PACKAGE_VERSION

mkdir prefix
export PREFIX=$(pwd)/prefix

export BOOST_ROOT=${BOOST_PREFIX}
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


#pyproject.toml
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/t/thrift-cpp/pyproject.toml
sed -i s/{PACKAGE_VERSION}/$PACKAGE_VERSION/g pyproject.toml

mkdir -p local/thriftcpp
cp -r prefix/* local/thriftcpp/

python3.14 -m pip wheel -w $SCRIPT_DIR -vv --no-build-isolation --no-deps .

#install
if ! (python3.14 -m pip install .) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

