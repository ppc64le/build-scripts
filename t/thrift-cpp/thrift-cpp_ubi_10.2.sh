#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : thrift-cpp
# Version       : 0.21.0
# Source repo   : https://github.com/apache/thrift
# Tested on     : UBI:10.2
# Language      : Python, C++
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Sakshi Jain <sakshi.jain16@ibm.com>
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=thrift-cpp
PACKAGE_DIR=thrift
PACKAGE_VERSION=${1:-0.21.0}
PACKAGE_URL=https://github.com/apache/thrift

FLEX_VERSION=2.6.4
BISON_VERSION=3.8.2
BOOST_VERSION=boost-1.81.0

CURRENT_DIR="$(pwd)"
MAX_JOBS=${MAX_JOBS:-$(nproc)}

yum install -y python3.14 python3.14-pip python3.14-devel git make openssl-devel cmake zlib-devel libjpeg-devel gcc gcc-c++ libevent libevent-devel libtool wget autoconf automake pkgconfig diffutils file

# Installing flex bison

echo "-----------flex installing------------------"

cd $CURRENT_DIR

wget https://github.com/westes/flex/releases/download/v${FLEX_VERSION}/flex-${FLEX_VERSION}.tar.gz
tar -xvf flex-${FLEX_VERSION}.tar.gz
cd flex-${FLEX_VERSION}

echo "Configuring flex installation..."
./configure --prefix=/usr/local

echo "Compiling the source code for flex..."
make -j${MAX_JOBS}

echo "Installing flex..."
make install

export PATH="/usr/local/bin:${PATH}"

cd $CURRENT_DIR

echo "-------bison installing----------------------"

wget https://ftp.gnu.org/gnu/bison/bison-${BISON_VERSION}.tar.gz
tar -xvf bison-${BISON_VERSION}.tar.gz
cd bison-${BISON_VERSION}

echo "Configuring bison installation..."
./configure --prefix=/usr/local

echo "Compiling the source code bison..."
make -j${MAX_JOBS}

echo "Installing bison..."
make install

export PATH="/usr/local/bin:${PATH}"

cd $CURRENT_DIR

if ! command -v yacc >/dev/null 2>&1; then
    ln -sf "$(command -v bison)" /usr/local/bin/yacc
fi

echo "Checking build tools:"
command -v flex
command -v bison
command -v yacc

# installing boost

git clone https://github.com/boostorg/boost
cd boost
git checkout ${BOOST_VERSION}
git submodule update --init --recursive

mkdir Boost_prefix
export BOOST_PREFIX=$(pwd)/Boost_prefix

INCLUDE_PATH="${BOOST_PREFIX}/include"
LIBRARY_PATH="${BOOST_PREFIX}/lib"

export CC=$(which gcc)
export CXX=$(which g++)
export target_platform=$(uname)-$(uname -m)
CXXFLAGS="${CXXFLAGS:-} -fPIC"
TOOLSET=gcc

cat <<EOF > tools/build/example/site-config.jam
using ${TOOLSET} : : ${CXX} ;
EOF

LINKFLAGS="${LINKFLAGS:-} -L${LIBRARY_PATH}"

export CXXFLAGS="$(echo "${CXXFLAGS:-}" \
    | sed 's/ -march=[^ ]*//g' \
    | sed 's/ -mcpu=[^ ]*//g' \
    | sed 's/ -mtune=[^ ]*//g') -fPIC"

export CFLAGS="$(echo "${CFLAGS:-}" \
    | sed 's/ -march=[^ ]*//g' \
    | sed 's/ -mcpu=[^ ]*//g' \
    | sed 's/ -mtune=[^ ]*//g')"

./bootstrap.sh \
    --prefix="${BOOST_PREFIX}" \
    --without-libraries=python \
    --with-toolset="${TOOLSET}" || (cat bootstrap.log; exit 1)

ADDRESS_MODEL=64
ARCHITECTURE=power
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

rm -f "${BOOST_PREFIX}/include/boost/python.hpp"
rm -rf "${BOOST_PREFIX}/include/boost/python"

cd $CURRENT_DIR

echo "------------------- boost installed-------------------"

# clone source repository

git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION

Source_DIR=$(pwd)

mkdir prefix
export PREFIX=$Source_DIR/prefix

export BOOST_ROOT=${BOOST_PREFIX}
export ZLIB_ROOT=/usr
export LIBEVENT_ROOT=/usr

export OPENSSL_ROOT=/usr
export OPENSSL_ROOT_DIR=/usr

# Thrift 0.21.0 Mutex fix

MUTEX_HEADER="lib/cpp/src/thrift/concurrency/Mutex.h"

if [ ! -f "${MUTEX_HEADER}" ]; then
    echo "ERROR: ${MUTEX_HEADER} not found"
    exit 1
fi

if ! grep -q '#include <cstdint>' "${MUTEX_HEADER}"; then
    sed -i '/#include <thrift\/TNonCopyable.h>/a #include <cstdint>' "${MUTEX_HEADER}"
fi

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
    --with-zlib=$ZLIB_ROOT \
    --with-libevent=$LIBEVENT_ROOT \
    --with-boost=$BOOST_ROOT \
    --with-openssl=$OPENSSL_ROOT \
    --enable-tests=no \
    --enable-tutorial=no

if ! make -j${MAX_JOBS}; then
    echo "------------------$PACKAGE_NAME:Build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Build_Fails"
    exit 1
fi

if ! make install; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 1
fi

cd $Source_DIR
mkdir -p local/thriftcpp

cp -r $PREFIX/* local/thriftcpp/

#pyproject.toml

wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/t/thrift-cpp/pyproject.toml
sed -i s/{PACKAGE_VERSION}/$PACKAGE_VERSION/g pyproject.toml

#test

if ! make -k check; then
    echo "--------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi

