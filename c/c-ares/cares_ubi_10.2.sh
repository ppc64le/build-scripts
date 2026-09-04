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

PACKAGE_NAME="c-ares"
PACKAGE_VERSION="${1:-cares-1_19_1}"
PACKAGE_URL="https://github.com/c-ares/c-ares.git"
CURRENT_DIR="$(pwd -P)"

yum install -y \
    wget \
    python3.14 \
    python3.14-pip \
    python3.14-devel \
    git \
    make \
    cmake \
    glibc-devel \
    findutils \
    diffutils \
    xz \
    gcc-toolset-15 \
    gcc-toolset-15-gcc \
    gcc-toolset-15-gcc-c++

export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export LD_LIBRARY_PATH="/opt/rh/gcc-toolset-15/root/usr/lib64"

export CC="/opt/rh/gcc-toolset-15/root/usr/bin/gcc"
export CXX="/opt/rh/gcc-toolset-15/root/usr/bin/g++"

unset LIBRARY_PATH
unset GCC_EXEC_PREFIX
unset COMPILER_PATH
unset LDFLAGS
unset CFLAGS
unset CXXFLAGS
unset CPPFLAGS
unset CMAKE_ARGS
unset PKG_CONFIG_PATH
unset BINUTILS_ROOT
unset LD

# # Build PATCHELF from source
# PATCHELF_VERSION="0.18.0"
# PATCHELF_SRC_DIR="${CURRENT_DIR}/patchelf-${PATCHELF_VERSION}-src"

# cd "${CURRENT_DIR}"

# rm -rf "${PATCHELF_SRC_DIR}"
# rm -f "patchelf-${PATCHELF_VERSION}.tar.gz"

# wget -q \
#     "https://github.com/NixOS/patchelf/archive/refs/tags/${PATCHELF_VERSION}.tar.gz" \
#     -O "patchelf-${PATCHELF_VERSION}.tar.gz"

# tar -xf "patchelf-${PATCHELF_VERSION}.tar.gz"

# mv \
#     "patchelf-${PATCHELF_VERSION}" \
#     "${PATCHELF_SRC_DIR}"

# cd "${PATCHELF_SRC_DIR}"

# ./bootstrap.sh
# ./configure --prefix=/usr/local
# make -j"$(nproc)"
# make install

# which patchelf
# patchelf --version

# ---------------------------------------------------------------------------
# Build and install GNU binutils from source
# ---------------------------------------------------------------------------
BINUTILS_VERSION="2.45"
BINUTILS_SRC_DIR="${CURRENT_DIR}/binutils-${BINUTILS_VERSION}-src"
BINUTILS_BUILD_DIR="${CURRENT_DIR}/binutils-${BINUTILS_VERSION}-build"
BINUTILS_INSTALL_DIR="${CURRENT_DIR}/binutils-${BINUTILS_VERSION}"

cd "${CURRENT_DIR}"

rm -rf \
    "${BINUTILS_SRC_DIR}" \
    "${BINUTILS_BUILD_DIR}" \
    "${BINUTILS_INSTALL_DIR}"

rm -f "binutils-${BINUTILS_VERSION}.tar.xz"

wget -q \
    "https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.xz"

tar -xf "binutils-${BINUTILS_VERSION}.tar.xz"

mv \
    "binutils-${BINUTILS_VERSION}" \
    "${BINUTILS_SRC_DIR}"

mkdir -p "${BINUTILS_BUILD_DIR}"

cd "${BINUTILS_BUILD_DIR}"

"${BINUTILS_SRC_DIR}/configure" \
    --prefix="${BINUTILS_INSTALL_DIR}" \
    --disable-nls \
    --disable-werror

make -j"$(nproc)"
make install

export AR="${BINUTILS_INSTALL_DIR}/bin/ar"
export RANLIB="${BINUTILS_INSTALL_DIR}/bin/ranlib"

# install dependency
python3.14 -m pip install --upgrade pip
python3.14 -m pip install setuptools ninja build wheel auditwheel

# clone source repository
cd $CURRENT_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

mkdir -p prefix
export PREFIX="$(pwd)/prefix"
mkdir cmake-build 
cd cmake-build

export CARES_STATIC=OFF                                                                                                           
export CARES_SHARED=ON                                                                                                            

cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DCARES_STATIC="${CARES_STATIC}" \
    -DCARES_SHARED="${CARES_SHARED}" \
    -DCARES_INSTALL=ON \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCARES_BUILD_TOOLS=OFF \
    -DCARES_BUILD_TESTS=ON \
    -DCMAKE_AR="${AR}" \
    -DCMAKE_RANLIB="${RANLIB}" \
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