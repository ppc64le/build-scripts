#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pynacl
# Version       : 1.5.0
# Source repo   : https://github.com/pyca/pynacl
# Tested on     : UBI:10.2
# Language      : Python, C
# Ci-Check      : True
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

PACKAGE_NAME=pynacl
PACKAGE_VERSION=${1:-1.5.0}
PACKAGE_URL=https://github.com/pyca/pynacl
PACKAGE_DIR=pynacl
WORKDIR="$(pwd -P)"
WORKDIR="${WORKDIR%/}"

# ---------------------------------------------------------------------------
# System dependencies
# ---------------------------------------------------------------------------
echo "Installing dependencies..."
dnf install -y --allowerasing git gcc gcc-c++ make cmake \
    python3 python3-pip python3-devel libffi libffi-devel

# ---------------------------------------------------------------------------
# CPU optimization flags
# ---------------------------------------------------------------------------
if grep -q "POWER10" /proc/cpuinfo 2>/dev/null; then
    CPU_FLAGS="-mcpu=power10 -mtune=power10 -O3"
    echo "Detected POWER10 - applying power10 optimization flags"
else
    CPU_FLAGS="-O3"
    echo "POWER10 not detected - standard optimization flags applied"
fi

export CFLAGS="${CPU_FLAGS}"
export CXXFLAGS="${CPU_FLAGS}"

# ---------------------------------------------------------------------------
# Clone
# ---------------------------------------------------------------------------
cd "${WORKDIR}"
rm -rf "${PACKAGE_DIR}"

echo "Cloning ${PACKAGE_NAME}..."
if ! git clone "${PACKAGE_URL}" "${PACKAGE_DIR}"; then
    echo "------------------${PACKAGE_NAME}:clone_fails---------------------------------------"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | Fail | Clone_Fails"
    exit 1
fi

cd "${PACKAGE_DIR}"
git checkout "${PACKAGE_VERSION}"
git submodule update --init --recursive

# ---------------------------------------------------------------------------
# Build wheel
# ---------------------------------------------------------------------------
python3 -m pip install --upgrade pip

if ! python3 -m pip install setuptools wheel build cffi; then
    echo "------------------${PACKAGE_NAME}:build_requirements_install_fails------------------"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | Fail | Build_Requirements_Install_Fails"
    exit 1
fi

echo "Building ${PACKAGE_NAME} wheel with Power 10 optimizations..."
mkdir -p "${WORKDIR}/dist"
if ! python3 -m build --wheel --no-isolation --outdir "${WORKDIR}/dist"; then
    echo "------------------${PACKAGE_NAME}:wheel_build_fails---------------------------------"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | Fail | Wheel_Build_Fails"
    exit 1
fi

WHEEL=$(find "${WORKDIR}/dist" -maxdepth 1 -type f -iname "${PACKAGE_NAME}-*.whl" | head -1)
if [ -z "${WHEEL}" ]; then
    echo "------------------${PACKAGE_NAME}:wheel_not_found-----------------------------------"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | Fail | Wheel_Not_Found"
    exit 1
fi
echo "Found wheel: ${WHEEL}"

# ---------------------------------------------------------------------------
# Create virtual environment and install wheel
# ---------------------------------------------------------------------------
cd "${WORKDIR}"
rm -rf "${WORKDIR}/test_venv"
python3 -m venv "${WORKDIR}/test_venv"
source "${WORKDIR}/test_venv/bin/activate"

python3 -m pip install --upgrade pip
if ! python3 -m pip install --force-reinstall "${WHEEL}"; then
    echo "------------------${PACKAGE_NAME}:install_fails-------------------------------------"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | Fail | Install_Fails"
    exit 1
fi

# ---------------------------------------------------------------------------
# Smoke test
# ---------------------------------------------------------------------------
echo "Validating ${PACKAGE_NAME} installation..."
if ! python3 -c "import nacl, nacl.secret, nacl.signing, nacl.bindings; print('${PACKAGE_NAME} version:', nacl.__version__)"; then
    echo "------------------${PACKAGE_NAME}:install_success_but_test_fails---------------------"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | Fail | Validation_Fails"
    exit 2
fi

# ---------------------------------------------------------------------------
# Test
# ---------------------------------------------------------------------------
python3 -m pip install pytest hypothesis
echo "Running upstream ${PACKAGE_NAME} tests against installed wheel..."
cd "${WORKDIR}/${PACKAGE_DIR}"
if ! python3 -m pytest tests -v --tb=short; then
    echo "------------------${PACKAGE_NAME}:install_success_but_test_fails---------------------"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | Fail | Test_Fails"
    exit 2
fi

echo "------------------${PACKAGE_NAME}:install_&_test_both_success-------------------------"
exit 0
