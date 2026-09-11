#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : sentencepiece
# Version          : v0.2.2
# Source repo      : https://github.com/google/sentencepiece.git
# Tested on        : UBI:10.2
# Language         : Python
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : tejasBadjateIBM <Tejas.Badjate@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

set -ex

PACKAGE_NAME=sentencepiece
PACKAGE_VERSION=${1:-v0.2.2}
PACKAGE_URL=https://github.com/google/sentencepiece.git
PACKAGE_DIR=sentencepiece/python

yum install -y make libtool git wget tar xz zlib-devel openssl-devel bzip2-devel libffi-devel libevent-devel patch python3.14 python3.14-pip python3.14-devel ninja-build pkg-config cmake

yum install gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ gcc-toolset-15-gcc-gfortran -y

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

PYTHON_VERSION=python$(python3.14 --version 2>&1 | cut -d ' ' -f 2 | cut -d '.' -f 1,2)

export SITE_PACKAGE_PATH="/lib/${PYTHON_VERSION}/site-packages"
SCRIPT_DIR=$(pwd)

python3.14 -m pip install --upgrade pip "setuptools<80" wheel ninja packaging pytest

cd $SCRIPT_DIR

#Building sentencepiece
echo " -------------------------- Sentencepiece Installing -------------------------- "

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

echo "-------------------------- Patch license metadata --------------------------"
cd python

cp -f ../LICENSE . 2>/dev/null || true

if ! grep -q '^license *=.*' pyproject.toml; then
    echo "Patching pyproject.toml to include license..."

    sed -i '/^\[project\]$/a license = "Apache-2.0"' pyproject.toml
    sed -i '/^license = "Apache-2.0"$/a license-files = ["LICENSE"]' pyproject.toml
fi

# Ensure LICENSE included in source dist
if [ ! -f MANIFEST.in ]; then
    echo "include LICENSE" > MANIFEST.in
elif ! grep -q LICENSE MANIFEST.in; then
    echo "include LICENSE" >> MANIFEST.in
fi

cd ..

export PATH="$LIBPROTO_INSTALL/bin:${PATH}"
export LD_LIBRARY_PATH="$LIBPROTO_INSTALL/lib:${LD_LIBRARY_PATH}"
export CMAKE_PREFIX_PATH="$LIBPROTO_INSTALL"  # ADDED: Let CMake find protobuf/abseil

export GCC_AR="${GCC_HOME}/bin/ar"
mkdir -p ${SCRIPT_DIR}/custom_libs
ln -s /usr/lib64/libatomic.so.1 ${SCRIPT_DIR}/custom_libs/libatomic.so
export LD_LIBRARY_PATH="${SCRIPT_DIR}/custom_libs:${LD_LIBRARY_PATH}"

ARCH=`uname -p`
if [[ "${ARCH}" == 'ppc64le' ]]; then
    ARCH_SO_NAME="powerpc64le"
    export LDFLAGS="${LDFLAGS} -L${VIRTUAL_ENV}/lib -L${SCRIPT_DIR}/custom_libs"
else
    ARCH_SO_NAME=${ARCH}
fi

PAGE_SIZE=`getconf PAGE_SIZE`
export LIBRARY_PATH=/usr/lib/gcc/ppc64le-redhat-linux/14:$LIBRARY_PATH
mkdir build
cd build
cmake -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    -DCMAKE_INSTALL_PREFIX="${HOME}" \
    -DSPM_BUILD_TEST=ON \
    -DSPM_ENABLE_TCMALLOC=OFF \
    -DSPM_USE_BUILTIN_PROTOBUF=ON \
    -DCMAKE_AR=${GCC_AR} \
    ..
make -j $(nproc)
make install
cd ../python

python3.14 -m pip install pybind11 setuptools protobuf==6.33.6
unset PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION
unset PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION_VERSION

if ! python3.14 -m pip install . --no-build-isolation; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! python3.14 -m pytest  ; then
    echo "------------------$PACKAGE_NAME:test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME "
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | Github | Fail |  Test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:test_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME "
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | Github | Pass |  Test_Success"
	exit 0
fi