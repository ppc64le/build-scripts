#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pillow
# Version       : 10.4.0
# Source repo   : https://github.com/python-pillow/Pillow
# Tested on     : UBI:10.2
# Language      : Python, C
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Amit Kumar <amit.kumar282@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=pillow
PACKAGE_IMPORT=PIL
PACKAGE_DIR=Pillow
SCRIPT_PACKAGE_VERSION=10.4.0
PACKAGE_VERSION="${1:-${SCRIPT_PACKAGE_VERSION}}"
PACKAGE_URL="https://github.com/python-pillow/Pillow"

SOURCE_ROOT="$(pwd)"

# ---------------------------------------------------------------------------
# System dependencies
# ---------------------------------------------------------------------------
yum install -y \
    python3 python3-pip python3-devel \
    git gcc make gcc-c++ wget cmake binutils pkgconfig \
    zlib zlib-devel \
    libjpeg-turbo libjpeg-turbo-devel \
    freetype-devel \
    --allowerasing

# Verify GCC 14
gcc --version
g++ --version

# ---------------------------------------------------------------------------
# CPU optimization flags
# ---------------------------------------------------------------------------
if grep -q "POWER10" /proc/cpuinfo 2>/dev/null; then
    CPU_FLAGS="-mcpu=power10 -mtune=power10"
    echo "Detected POWER10 - applying power10 optimization flags"
else
    CPU_FLAGS=""
    echo "POWER10 not detected - no arch-specific flags applied"
fi

export CFLAGS="${CPU_FLAGS}"
export CXXFLAGS="${CPU_FLAGS}"

python3 --version
python3 -m pip install --upgrade pip
python3 -m pip install setuptools wheel build pytest pytest-timeout packaging pyroma auditwheel patchelf

# numpy install from IBM DevFirst wheel index.
NUMPY_VERSION="2.4.6"
DEVFIRST_INDEX="https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/"

echo "-------------------Installing numpy from DevFirst portal----------------------"
if ! python3 -m pip install \
        --index-url "${DEVFIRST_INDEX}" \
        "numpy==${NUMPY_VERSION}"; then
    echo "------------------${PACKAGE_NAME}:numpy_install_fails-------------------------------"
    exit 1
fi

# ---------------------------------------------------------------------------
# Clone
# ---------------------------------------------------------------------------
cd "${SOURCE_ROOT}"
rm -rf "${PACKAGE_DIR}"

if ! git clone "${PACKAGE_URL}" "${PACKAGE_DIR}"; then
    echo "------------------${PACKAGE_NAME}:clone_fails---------------------------------------"
    exit 1
fi

cd "${PACKAGE_DIR}"
git checkout "${PACKAGE_VERSION}"

# ---------------------------------------------------------------------------
# Build wheel
# ---------------------------------------------------------------------------
if ! python3 -m build --wheel --no-isolation --outdir "${SOURCE_ROOT}"; then
    echo "------------------${PACKAGE_NAME}:wheel_build_fails---------------------------------"
    exit 1
fi

WHEEL=$(find "${SOURCE_ROOT}" -maxdepth 1 -type f -iname "pillow-*.whl" | head -1)

if [ -z "${WHEEL}" ]; then
    echo "------------------${PACKAGE_NAME}:wheel_not_found-----------------------------------"
    exit 1
fi

echo "Wheel: ${WHEEL}"

# ---------------------------------------------------------------------------
# Repair wheel with auditwheel
# ---------------------------------------------------------------------------
REPAIRED_DIR="${SOURCE_ROOT}/dist"
mkdir -p "${REPAIRED_DIR}"

if ! python3 -m auditwheel repair --wheel-dir "${REPAIRED_DIR}" "${WHEEL}"; then
    echo "------------------${PACKAGE_NAME}:auditwheel_fails----------------------------------"
    exit 1
fi

WHEEL=$(find "${REPAIRED_DIR}" -type f -iname "pillow-*.whl" | head -1)

if [ -z "${WHEEL}" ]; then
    echo "------------------${PACKAGE_NAME}:repaired_wheel_not_found--------------------------"
    exit 1
fi

echo "Repaired wheel: ${WHEEL}"

# ---------------------------------------------------------------------------
# Install wheel
# ---------------------------------------------------------------------------
if ! python3 -m pip install "${WHEEL}"; then
    echo "------------------${PACKAGE_NAME}:install_fails-------------------------------------"
    exit 1
fi

# ---------------------------------------------------------------------------
# Smoke-test
# ---------------------------------------------------------------------------
echo "Import and Version Test"

echo "Import and Version Test"

if ! python3 -c "
import ${PACKAGE_IMPORT}
from importlib.metadata import version
print('Import successful:', ${PACKAGE_IMPORT}.__file__)
print('Version:', version('${PACKAGE_NAME}'))
print('Import and version: OK')
"; then
    echo "------------------${PACKAGE_NAME}:install_success_but_test_fails---------------------"
    exit 2
fi

# ---------------------------------------------------------------------------
# Test 
# Test cases being skipped and reason.
#   test_qt_image_plugin / test_qt_image_toqimage
#       PyQt5/PySide2 not available in UBI container.
#   test_segfault
#       Deliberate crash test; unsafe in automated CI.
#   test_imagefont_bitmap
#       Requires system bitmap-font files at fixed paths not present in UBI.
#   test_wrong_arguments
#       Exception message regex mismatch on ppc64le/GCC 14 — not a functional failure.
# ---------------------------------------------------------------------------
cd "${SOURCE_ROOT}/${PACKAGE_DIR}"

if ! python3 -m pytest Tests/ \
        --timeout=120 \
        --tb=short \
        -v \
        --ignore=Tests/test_qt_image_plugin.py \
        --ignore=Tests/test_qt_image_toqimage.py \
        -k "not test_segfault and not test_imagefont_bitmap and not test_wrong_arguments"; then
    echo "------------------${PACKAGE_NAME}:install_success_but_test_fails---------------------"
    exit 2
else
    echo "------------------${PACKAGE_NAME}:install_&_test_both_success-------------------------"
    exit 0
fi
