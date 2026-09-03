#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : c-ares
# Version       : cares-1_19_1
# Source repo   : https://github.com/c-ares/c-ares.git
# Tested on     : UBI:10.2
# Language      : c
# Ci-Check  : True
# Script License: Apache License 2.0
# Maintainer    : tejasBadjateIBM <Tejas.Badjate@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e 

PACKAGE_NAME=c-ares
PACKAGE_VERSION=${1:-cares-1_19_1}
PACKAGE_URL=https://github.com/c-ares/c-ares.git
CURRENT_DIR=$(pwd)
PACKAGE_DIR=c-ares

echo "------------------------Installing dependencies-------------------"
yum install -y wget

# install core dependencies
yum install -y \
    python3.14 \
    python3.14-pip \
    python3.14-devel \
    git \
    make \
    cmake \
    glibc-devel \
    findutils \
    diffutils \
    xz

yum install gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ -y

# ---------------------------------------------------------------------------
# Activate GCC Toolset 15 (SCL removed in UBI 10 — use PATH export)
# ---------------------------------------------------------------------------
if [[ -f /opt/rh/gcc-toolset-15/enable ]]; then
    source /opt/rh/gcc-toolset-15/enable
elif [[ -d /opt/rh/gcc-toolset-15/root/usr/bin ]]; then
    export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"
    export LD_LIBRARY_PATH="/opt/rh/gcc-toolset-15/root/usr/lib64:$LD_LIBRARY_PATH"
else
    echo "ERROR: gcc-toolset-15 not found"
    exit 1
fi

export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"
export LD_LIBRARY_PATH="/opt/rh/gcc-toolset-15/root/usr/lib64:${LD_LIBRARY_PATH:-}"

export CC="/opt/rh/gcc-toolset-15/root/usr/bin/gcc"
export CXX="/opt/rh/gcc-toolset-15/root/usr/bin/g++"

# ---------------------------------------------------------------------------
# Build and install GNU binutils from source
# ---------------------------------------------------------------------------
BINUTILS_VERSION=2.47
BINUTILS_SRC_DIR="${CURRENT_DIR}/binutils-${BINUTILS_VERSION}"
BINUTILS_BUILD_DIR="${CURRENT_DIR}/binutils-${BINUTILS_VERSION}-build"
BINUTILS_INSTALL_DIR="${CURRENT_DIR}/binutils-${BINUTILS_VERSION}"

cd "${CURRENT_DIR}"

wget -q "https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.xz"
tar -xf "binutils-${BINUTILS_VERSION}.tar.xz"

rm -rf "${BINUTILS_BUILD_DIR}"
mkdir -p "${BINUTILS_BUILD_DIR}"
cd "${BINUTILS_BUILD_DIR}"

"${BINUTILS_SRC_DIR}/configure" \
    --prefix="${BINUTILS_INSTALL_DIR}" \
    --disable-nls \
    --disable-werror

make -j"$(nproc)"
make install

# ---------------------------------------------------------------------------
# Use source-built binutils
# ---------------------------------------------------------------------------
export BINUTILS_ROOT="${BINUTILS_INSTALL_DIR}"
export PATH="${BINUTILS_ROOT}/bin:${PATH}"
export LD_LIBRARY_PATH="${BINUTILS_ROOT}/lib:${LD_LIBRARY_PATH:-}"
export CPPFLAGS="-I${BINUTILS_ROOT}/include ${CPPFLAGS:-}"
export LDFLAGS="-L${BINUTILS_ROOT}/lib ${LDFLAGS:-}"
export PKG_CONFIG_PATH="${BINUTILS_ROOT}/lib/pkgconfig:${PKG_CONFIG_PATH:-}"

# Verify
echo "Using binutils:"
which ar
which ld
which as

ar --version
ld --version
as --version

# Verify development files
test -f "${BINUTILS_ROOT}/include/bfd.h"
test -f "${BINUTILS_ROOT}/lib/libbfd.a"

echo "binutils ${BINUTILS_VERSION} installed successfully"

# ------------------------------------------------------------------------------------

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

target_platform=$(uname)-$(uname -m)
AR=$(which ar)

# install dependency
python3.14 -m pip install --upgrade pip
python3.14 -m pip install setuptools ninja build wheel

# clone source repository
cd $CURRENT_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

mkdir -p prefix
export PREFIX=$(pwd)/prefix
mkdir cmake-build && cd cmake-build

export CARES_STATIC=OFF                                                                                                           
export CARES_SHARED=ON                                                                                                            
export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_AR=${AR}"   

cmake ${CMAKE_ARGS} .. \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX="$PREFIX" \
      -DCARES_STATIC=${CARES_STATIC} \
      -DCARES_SHARED=${CARES_SHARED} \
      -DCARES_INSTALL=ON \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DCARES_BUILD_TOOLS=OFF \
      -DCARES_BUILD_TESTS=ON \
      -GNinja

echo "-------------------------------------------------------Building the package-------------------------------------"

#Build package
if ! (ninja && ninja install) ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

cd ..
mkdir -p local/cares
cp -r prefix/* local/cares

#During wheel creation for this package we need exported cmake-args. Once script get exit, and if we build wheel through wrapper script, then those are not applicable during wheel creation. So we are generating wheel for this package in script itself.

echo "---------------------------------------------------Building the wheel--------------------------------------------------"

WHL_VERSION=$(echo "$PACKAGE_VERSION" | grep -oE '[0-9_]+$' | tr '_' '.')
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/c/c-ares/pyproject.toml
sed -i "s/{PACKAGE_VERSION}/$WHL_VERSION/g" pyproject.toml

python3.14 -m build --wheel --no-isolation --outdir="$CURRENT_DIR/" -v

echo "----------------------------------------------Testing pkg-------------------------------------------------------"
cd cmake-build
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