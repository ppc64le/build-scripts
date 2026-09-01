#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pillow
# Version       : 12.3.0
# Source repo   : https://github.com/python-pillow/Pillow
# Tested on     : UBI:10.2
# Language      : Python, C
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Sakshi Jain <sakshi.jain16@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=pillow
PACKAGE_IMPORT=PIL
PACKAGE_DIR=Pillow
PACKAGE_VERSION="${1:-12.3.0}"
PACKAGE_VERSION="${PACKAGE_VERSION#v}"
PACKAGE_URL="https://github.com/python-pillow/Pillow.git"
SOURCE_ROOT="$(pwd)"

GCC_HOME=/opt/rh/gcc-toolset-15/root/usr

yum install -y python3.14 python3.14-pip python3.14-devel git gcc make gcc-c++ gcc-toolset-15 gcc-toolset-15-binutils gcc-toolset-15-binutils-devel gcc-toolset-15-gcc-c++ cmake binutils pkgconfig zlib zlib-devel libjpeg-turbo libjpeg-turbo-devel wget freetype-devel

export PATH="${GCC_HOME}/bin:${PATH}"
export LD_LIBRARY_PATH="${GCC_HOME}/lib64:${LD_LIBRARY_PATH:-}"
export CC="${GCC_HOME}/bin/gcc"
export CXX="${GCC_HOME}/bin/g++"

gcc --version

python3.14 -m pip install --upgrade pip

python3.14 -m pip install setuptools==77.0.1 wheel build pytest pybind11 numpy==2.5.0

cd "${SOURCE_ROOT}"

rm -rf "${PACKAGE_DIR}"
git clone "${PACKAGE_URL}"
cd "${PACKAGE_DIR}"

git checkout "${PACKAGE_VERSION}"
git submodule update --init

if ! python3.14 -m build --wheel --no-isolation --outdir "${SOURCE_ROOT}"; then
    echo "------------------${PACKAGE_NAME}:Wheel_build_fails-------------------------------------"
    echo "${PACKAGE_URL} ${PACKAGE_NAME}"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | GitHub | Fail | Wheel_build_fails"
    exit 1
fi

WHEEL=$(find "${SOURCE_ROOT}" -maxdepth 1 -type f -name "${PACKAGE_NAME}-*.whl" | head -1)

if [ -z "${WHEEL}" ]; then
    echo "ERROR: wheel not found after build"
    exit 1
fi

echo "Wheel: ${WHEEL}"

if ! python3.14 -m pip install "${WHEEL}"; then
    echo "------------------${PACKAGE_NAME}:Install_fails-------------------------------------"
    echo "${PACKAGE_URL} ${PACKAGE_NAME}"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | GitHub | Fail | Install_Fails"
    exit 1
fi

echo "Import and Version Test"

python3.14 -c "
import ${PACKAGE_IMPORT}
from importlib.metadata import version
print('Import successful:', ${PACKAGE_IMPORT}.__file__)
print('Version:', version('${PACKAGE_NAME}'))
print('Import and version: OK')
"

echo "Executing the Testcases"

cd "${SOURCE_ROOT}/${PACKAGE_DIR}"

if ! python3.14 -m pytest -k "not test_segfault"; then
    echo "------------------${PACKAGE_NAME}:Install_success_but_test_fails---------------------"
    echo "${PACKAGE_URL} ${PACKAGE_NAME}"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
else
    echo "------------------${PACKAGE_NAME}:Install_&_test_both_success-------------------------"
    echo "${PACKAGE_URL} ${PACKAGE_NAME}"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | GitHub | Pass | Both_Install_and_Test_Success"
    exit 0
fi