#!/bin/bash -ex
# ------------------------------------------------------------------------------
# Package        : lingua-language-detector
# Version        : 2.2.0
# Source repo    : https://github.com/pemistahl/lingua-rs
# Tested on      : UBI 9.6
# Language       : Rust with Python bindings
# Ci-Check       : True
# Maintainer     : Vijay Vinnakota <vijay.vinnakota@ibm.com>
# Scritp License : Apache License, Version 2 or later
# Build          : maturin (Rust + Python)
#
# Disclaimer     : This script has been tested in root mode on given
#                  platform using the mentioned version of the package.
#                  It may not work as expected with newer versions of the
#                  package and/or distribution. In such case, please
#                  contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
set -e

# Variables
PKG_NAME="lingua-language-detector"
PKG_VERSION="2.2.0"
PKG_ORG="pemistahl"
PKG_REPO="lingua-rs"
PKG_URL="https://github.com/${PKG_ORG}/${PKG_REPO}.git"
SRC_DIR="${PKG_REPO}"
IBM_SUFFIX="ppc64le1"

echo ""
echo "Building ${PKG_NAME} ${PKG_VERSION} for ppc64le (UBI 9.6, Python 3.12)"
echo ""

# ------------------------------------------------------------------------------
# Install dependencies (UBI 9.6 + RPM Python 3.12)
# ------------------------------------------------------------------------------

dnf install -y \
    python3.12 \
    python3.12-devel \
    python3.12-pip \
    gcc \
    gcc-c++ \
    make \
    git \
    rust \
    cargo \
    openssl-devel \
    libffi-devel \
    zlib-devel && \
dnf clean all

# Normalize Python commands
ln -sf /usr/bin/python3.12 /usr/bin/python3
ln -sf /usr/bin/pip-3.12 /usr/bin/pip3
ln -sf /usr/bin/python3.12 /usr/bin/python
ln -sf /usr/bin/pip-3.12 /usr/bin/pip

python --version
pip --version

# ------------------------------------------------------------------------------
# Python build tooling
# ------------------------------------------------------------------------------

pip install --upgrade pip setuptools wheel pytest
pip install maturin==1.13.1

# ------------------------------------------------------------------------------
# Clone source (lingua-rs is Git-only;)
# ------------------------------------------------------------------------------

git clone "${PKG_URL}"
if [ $? -ne 0 ]; then 
  echo "ERROR: Failed to clone repository"
  exit 1  
fi
cd "${SRC_DIR}" || exit 1

# ------------------------------------------------------------------------------
# Apply IBM Power suffix
# ------------------------------------------------------------------------------

sed -i \
  "s/^version = .*/version = \"${PKG_VERSION}+${IBM_SUFFIX}\"/" \
  pyproject.toml

if [ $? -ne 0 ]; then 
  echo "ERROR: Failed to update version in pyproject.toml"
  exit 1  
fi
grep '^version' pyproject.toml

# ------------------------------------------------------------------------------
# Build wheel
# ------------------------------------------------------------------------------
echo "Building wheel using maturin..."

maturin build --release --strip
if [ $? -ne 0 ]; then
  echo "ERROR: Wheel build failed"
  exit 1
fi

# ------------------------------------------------------------------------------
# Locate wheel
# ------------------------------------------------------------------------------

WHEEL_FILE="$(ls target/wheels/${PKG_NAME//-/_}-*.whl | head -n 1)"

if [[ ! -f "${WHEEL_FILE}" ]]; then
  echo "ERROR: Wheel file not found"
  exit 1
fi

echo "Built wheel: ${WHEEL_FILE}"

# ------------------------------------------------------------------------------
# Install wheel
# ------------------------------------------------------------------------------

pip install "${WHEEL_FILE}"
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to install built wheel"
  exit 1
fi

# ------------------------------------------------------------------------------
# Run upstream Python tests (tests/python)
# ------------------------------------------------------------------------------

echo "Running upstream Python tests with pytest..."
pytest tests/python
if [ $? -ne 0 ]; then
  echo "ERROR: Python test suite failed"
  exit 1
fi

echo ""
echo "SUCCESS: ${PKG_NAME} ${PKG_VERSION} built and validated"
echo ""
