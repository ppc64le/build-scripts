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

set -ex

PACKAGE_NAME=c-ares
PACKAGE_VERSION=${1:-cares-1_19_1}
PACKAGE_URL=https://github.com/c-ares/c-ares
WORK_DIR=$(pwd)

echo "Installing dependencies..."
yum install -y wget
yum install -y git make cmake python3.14 python3.14-devel python3.14-pip pkgconfig gcc-toolset-15
export PATH=/opt/rh/gcc-toolset-15/root/usr/bin:$PATH

#prerequisite
python3.14 -m pip install setuptools ninja build wheel

# Clone cares source repository
echo "Cloning the repository..."
if [ ! -d "$PACKAGE_NAME" ]; then
    git clone -b $PACKAGE_VERSION $PACKAGE_URL
fi
cd c-ares

target_platform=$(uname)-$(uname -m)
AR=$(which ar)
PKG_NAME=c-ares

mkdir -p prefix
export PREFIX=$(pwd)/prefix

echo "Building ${PKG_NAME}."
# Isolate the build.
mkdir -p build && cd build

if [[ "$PKG_NAME" == *static ]]; then
  CARES_STATIC=ON
  CARES_SHARED=OFF
else
  CARES_STATIC=OFF
  CARES_SHARED=ON
fi

if [[ "${target_platform}" == Linux-* ]]; then
  CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_AR=${AR}"
fi

# Generate the build files.
echo "Generating the build files..."
cmake ${CMAKE_ARGS} .. \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX="$PREFIX" \
      -DCARES_STATIC=${CARES_STATIC} \
      -DCARES_SHARED=${CARES_SHARED} \
      -DCARES_BUILD_TESTS=ON \
      -DCARES_INSTALL=ON \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -GNinja

ninja || exit 1
ninja install || exit 1

cd $WORK_DIR
mkdir -p local/cares

cp -r c-ares/prefix/* local/cares

#install pyproject.toml
WHL_VERSION=$(echo "$PACKAGE_VERSION" | grep -oE '[0-9_]+$' | tr '_' '.')
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/c/c-ares/pyproject.toml
sed -i "s/{PACKAGE_VERSION}/$WHL_VERSION/g" pyproject.toml

python3.14 -m pip wheel -w $WORK_DIR -vv --no-build-isolation --no-deps .

# Install locally built wheel for validation

WHEEL=$(find "$WORK_DIR" -maxdepth 1 -name "*.whl" | head -1)

if ! python3.14 -m pip install "${WHEEL}" --no-deps; then
    echo "------------------${PACKAGE_NAME}:Install_fails-------------------------------------"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | GitHub | Fail | Install_Fails"
    exit 1
fi
SITE_PACKAGE_PATH=$(python3.14 -m pip show c-ares | awk -F': ' '/^Location:/ {print $2}')

test -f ${SITE_PACKAGE_PATH}/cares/include/ares.h || { echo "ERROR: ares.h not exists." ; exit 1; }
test -f ${SITE_PACKAGE_PATH}/cares/lib/libcares.so || { echo "ERROR: libcares.so not exists." ; exit 1; }
test ! -f ${SITE_PACKAGE_PATH}/cares/lib/libcares.a || { echo "ERROR: libcares.a exists." ; exit 1; }
test ! -f ${SITE_PACKAGE_PATH}/cares/lib/libcares_static.a || { echo "ERROR: libcares_static.a exists." ; exit 1; }

echo "----------------------------------------------Testing pkg-------------------------------------------------------"
cd ${PACKAGE_NAME}/build/
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