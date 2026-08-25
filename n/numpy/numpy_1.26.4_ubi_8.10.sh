#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : numpy
# Version       : v1.26.4
# Source repo   : https://github.com/numpy/numpy.git
# Tested on     : UBI 8.10
# Language      : Python, C, Cython
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Amit Kumar <amit.kumar282@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# platform using the mentioned version of the package. It may not work
# as expected with newer versions of the package and/or distribution.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=numpy
PACKAGE_VERSION=${1:-v1.26.4}
PACKAGE_URL=https://github.com/numpy/numpy.git
PACKAGE_DIR=numpy
CURRENT_DIR=${PWD}

# -----------------------------------------------------------------------------
# 1. Install system dependencies
# -----------------------------------------------------------------------------

yum install -y python3.12 python3.12-devel python3.12-pip git make cmake ninja-build binutils wget gcc-toolset-13 gcc-toolset-13-binutils gcc-toolset-13-binutils-devel gcc-toolset-13-gcc-c++

# UBI 8.10 ships GCC 8.5.
# GCC Toolset 13 provides GCC 13.
source /opt/rh/gcc-toolset-13/enable

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:${LD_LIBRARY_PATH:-}

echo "GCC version: $(gcc --version | head -1)"
echo "Python version: $(python3.12 --version)"

# -----------------------------------------------------------------------------
# 2. Clone source repository
# -----------------------------------------------------------------------------

cd "$CURRENT_DIR"
[ -d "$PACKAGE_NAME" ] && rm -rf "$PACKAGE_NAME"
git clone "$PACKAGE_URL"
cd "$PACKAGE_NAME"
git checkout "$PACKAGE_VERSION"

# Initialise all submodules (NumPy 1.26.x vendors several C libraries
# such as lapack-lite, pocketfft, highway, etc. as git submodules)
git submodule update --init --recursive

# -----------------------------------------------------------------------------
# 3. Set package version
# -----------------------------------------------------------------------------

# Remove leading 'v'
PLAIN_VERSION="${PACKAGE_VERSION#v}"

# IBM local version label (PEP 440: 1.26.4+ppc64le1)
FULL_VERSION="${PLAIN_VERSION}+ppc64le1"
export SETUPTOOLS_SCM_PRETEND_VERSION="${FULL_VERSION}"

echo "Package version: ${PLAIN_VERSION}"
echo "Full version: ${FULL_VERSION}"

# -----------------------------------------------------------------------------
# 4. Create Python virtual environment
# -----------------------------------------------------------------------------

# Detect the Python interpreter provided
PYTHON_BIN=$(command -v python3 || command -v python)

# Create and activate virtual environment
"${PYTHON_BIN}" -m venv numpy-env
source numpy-env/bin/activate

# Use the Python interpreter from the virtual environment
PYTHON_BIN="${VIRTUAL_ENV}/bin/python"

echo "Using Python: ${PYTHON_BIN}"
echo "Python version: $(${PYTHON_BIN} --version)"

# -----------------------------------------------------------------------------
# 5. Install Python build dependencies
# -----------------------------------------------------------------------------

"${PYTHON_BIN}" -m pip install --upgrade pip wheel setuptools

# NumPy 1.26.x uses meson-python as its build backend.
# Cython and meson-python are pinned to the ranges declared in
# numpy/pyproject.toml: Cython<3.1,>=0.29.34 and meson-python<0.16.0,>=0.15.0
"${PYTHON_BIN}" -m pip install "Cython>=0.29.34,<3.1" "meson-python>=0.15.0,<0.16.0" pytest build meson ninja "versioneer[toml]" auditwheel patchelf

# -----------------------------------------------------------------------------
# 6. Configure Power compiler flags
# -----------------------------------------------------------------------------

# Power9-compatible code that also runs on Power9/Power10/Power11.
# -mcpu=native and Power10/Power11-only instructions are intentionally omitted.
export CFLAGS="-mcpu=power9 -mtune=power9 -O2"
export CXXFLAGS="-mcpu=power9 -mtune=power9 -O2"

echo "CFLAGS=${CFLAGS}"
echo "CXXFLAGS=${CXXFLAGS}"

# -----------------------------------------------------------------------------
# 7. Build numpy wheel
# -----------------------------------------------------------------------------

if "${PYTHON_BIN}" -m build --wheel --no-isolation; then
    echo "------------------$PACKAGE_NAME::Build_Pass---------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | Pass | Build_Success"
else
    echo "------------------$PACKAGE_NAME::Build_Fail---------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | Fail | Build_Fail"
    exit 1
fi

# -----------------------------------------------------------------------------
# 8. Verify source wheel
# -----------------------------------------------------------------------------

SOURCE_WHEEL=$(ls dist/numpy-*.whl 2>/dev/null | head -1)

if [ -z "${SOURCE_WHEEL}" ] || [ ! -f "${SOURCE_WHEEL}" ]; then
    echo "ERROR: numpy source wheel not found"
    exit 1
fi

echo "Source wheel: ${SOURCE_WHEEL}"

# -----------------------------------------------------------------------------
# 9. Run auditwheel
#
# This verifies the wheel can be repaired/tagged for
# manylinux_2_28_ppc64le.
# -----------------------------------------------------------------------------

mkdir -p wheelhouse

# Remove previously generated numpy wheels so that an old wheel
# cannot accidentally be selected.
rm -f wheelhouse/numpy-*.whl

echo "Running auditwheel repair..."

if auditwheel repair --plat manylinux_2_28_ppc64le --wheel-dir wheelhouse "${SOURCE_WHEEL}"; then
    echo "------------------$PACKAGE_NAME::Auditwheel_Pass---------------------"
    echo "Auditwheel repair successful"
else
    echo "------------------$PACKAGE_NAME::Auditwheel_Fail---------------------"
    echo "Auditwheel repair failed"
    exit 1
fi

# -----------------------------------------------------------------------------
# 10. Find repaired wheel
# -----------------------------------------------------------------------------

DUAL_WHEEL=$(ls wheelhouse/numpy-*.whl 2>/dev/null | head -1)

if [ -z "${DUAL_WHEEL}" ] || [ ! -f "${DUAL_WHEEL}" ]; then
    echo "ERROR: Repaired numpy wheel not found"
    exit 1
fi

echo "Auditwheel generated wheel: ${DUAL_WHEEL}"

# -----------------------------------------------------------------------------
# 11. Extract version, Python and ABI tags from SOURCE_WHEEL
# Example SOURCE_WHEEL:
# numpy-1.26.4-cp312-cp312-linux_ppc64le.whl
# -----------------------------------------------------------------------------

SOURCE_BASENAME=$(basename "${SOURCE_WHEEL}")

VERSION=$(echo "${SOURCE_BASENAME}" | cut -d'-' -f2)
PYTHON_TAG=$(echo "${SOURCE_BASENAME}" | cut -d'-' -f3)
ABI_TAG=$(echo "${SOURCE_BASENAME}" | cut -d'-' -f4)

if [ -z "${VERSION}" ] || [ -z "${PYTHON_TAG}" ] || [ -z "${ABI_TAG}" ]; then
    echo "ERROR: Unable to extract wheel metadata from source wheel"
    exit 1
fi

# -----------------------------------------------------------------------------
# 12. Construct required final wheel name
# -----------------------------------------------------------------------------

FINAL_WHEEL="wheelhouse/numpy-${VERSION}-${PYTHON_TAG}-${ABI_TAG}-manylinux_2_28_ppc64le.whl"

echo "Final wheel: ${FINAL_WHEEL}"

# -----------------------------------------------------------------------------
# 13. Rename auditwheel-generated wheel if necessary
# -----------------------------------------------------------------------------

if [ "${DUAL_WHEEL}" != "${FINAL_WHEEL}" ]; then

    if [ -f "${FINAL_WHEEL}" ]; then
        echo "ERROR: Final wheel already exists: ${FINAL_WHEEL}"
        exit 1
    fi

    mv "${DUAL_WHEEL}" "${FINAL_WHEEL}"

    echo "Renamed wheel: $(basename "${FINAL_WHEEL}")"

else

    echo "Wheel already has the expected filename: $(basename "${FINAL_WHEEL}")"

fi

# Verify final wheel exists
if [ ! -f "${FINAL_WHEEL}" ]; then
    echo "ERROR: Final wheel not found: ${FINAL_WHEEL}"
    exit 1
fi

echo "Final wheel ready: ${FINAL_WHEEL}"
# -----------------------------------------------------------------------------
# 14. Install generated wheel
# -----------------------------------------------------------------------------

if "${PYTHON_BIN}" -m pip install --only-binary=:all: "${FINAL_WHEEL}"; then
    echo "------------------$PACKAGE_NAME::Install_Pass---------------------"
else
    echo "------------------$PACKAGE_NAME::Install_Fail---------------------"
    exit 1
fi

# -----------------------------------------------------------------------------
# 15. Test installed numpy
# -----------------------------------------------------------------------------

cd ..

# -- 16a. Verify package metadata
"${PYTHON_BIN}" -m pip show numpy

# -- 16b. Smoke-test: import, config, and basic operations
"${PYTHON_BIN}" -c "
import numpy as np

print('Version :', np.__version__)
print('Location:', np.__file__)
np.show_config()

a = np.arange(1000, dtype=np.float64)
assert np.sum(a) == 499500.0,        'sum mismatch'

b = np.dot(a.reshape(10, 100), a.reshape(100, 10))
assert b.shape == (10, 10),          'dot shape mismatch'

print('Smoke tests passed')
"

# -- 16c. Report result
if [ $? -eq 0 ]; then
    echo "------------------$PACKAGE_NAME::Test_Pass---------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | Pass | Test_Success"
    deactivate
    exit 0
else
    echo "------------------$PACKAGE_NAME::Test_Fail---------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | Fail | Test_Fail"
    deactivate
    exit 2
fi
