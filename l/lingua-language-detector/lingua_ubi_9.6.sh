#!/bin/bash -ex
# ------------------------------------------------------------------------------
# Package        : lingua-language-detector
# Version        : 2.2.0
# Source repo    : https://github.com/pemistahl/lingua-rs
# Tested on      : UBI:9.6
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
PACKAGE_NAME="lingua-language-detector"
PACKAGE_VERSION="v1.8.0"
PACKAGE_ORG="pemistahl"
PACKAGE_DIR="lingua-rs"
PACKAGE_URL="https://github.com/${PACKAGE_ORG}/${PACKAGE_DIR}.git"
SOURCE="GitHub"

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')

echo ""
echo "Building ${PACKAGE_NAME} ${PACKAGE_VERSION} on ${OS_NAME}"
echo ""

# ------------------------------------------------------------------------------
# Install dependencies (UBI 9.6 + RPM Python 3.12)
# ------------------------------------------------------------------------------

dnf install -y python3.12 python3.12-devel python3.12-pip gcc gcc-c++ make git rust cargo openssl-devel libffi-devel zlib-devel && dnf clean all

# ------------------------------------------------------------------------------
# Python build tooling
# ------------------------------------------------------------------------------

python3.12 -m pip install --upgrade pip setuptools wheel pytest
python3.12 -m pip install maturin==1.13.1

# ------------------------------------------------------------------------------
# Clone source (lingua-rs is Git-only;)
# ------------------------------------------------------------------------------

if [[ "${PACKAGE_URL}" == *"github.com"* ]]; then
  if [ -d "${PACKAGE_DIR}" ]; then
    cd "${PACKAGE_DIR}" || exit 1
  else
    if ! git clone "${PACKAGE_URL}" "${PACKAGE_DIR}"; then
      echo "------------------${PACKAGE_NAME}:clone_fails---------------------------------------"
      echo "${PACKAGE_URL} ${PACKAGE_NAME}"
      echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | ${OS_NAME} | ${SOURCE} | Fail | Clone_Fails"
      exit 1
    fi
    # Checkout the requested version 
    cd "${PACKAGE_DIR}" || exit 1
    git checkout "${PACKAGE_VERSION}" || exit 1
    
  fi
else
  echo "ERROR: PACKAGE_URL is not a GitHub URL: ${PACKAGE_URL}"
  exit 1
fi


# ------------------------------------------------------------------------------
# Build wheel
# ------------------------------------------------------------------------------
echo "Building and installing package using pip (maturin as backend)"

python3.12 -m pip install . --no-build-isolation
if [ $? -ne 0 ]; then
    echo "------------------$PACKAGE_NAME:install_fails------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Install_Failed"
    exit 1
fi

# ------------------------------------------------------------------------------
# Run upstream Python tests (tests/python)
# ------------------------------------------------------------------------------

echo "Running upstream Python tests with pytest..."
test_status=1  # 0 = success, non-zero = failure

cd tests
if [ $? -ne 0 ]; then
    echo "ERROR: tests directory not found"
    exit 1
fi

# Run pytest if any matching test files found
if ls */test_*.py > /dev/null 2>&1 && [ $test_status -ne 0 ]; then
    echo "Running pytest..."
    (python3.12 -m pytest) && test_status=0 || test_status=$?
fi

cd -

## ------------------------------------------------------------------------------
## Final test result output (template block)
## ------------------------------------------------------------------------------

if [ $test_status -eq 0 ]; then
    echo "------------------$PACKAGE_NAME:install_and_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Pass | Both_Install_and_Test_Success"
    exit 0
else
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Install_success_but_test_Fails"
    exit 2
fi
