#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pycryptodome
# Version       : v4.3.0
# Source repo   : https://github.com/Legrandin/pycryptodome
# Tested on     : UBI:9.6
# Language      : C, Python
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Vinit Janbandhu <Vinit.Janbandhu@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

PACKAGE_NAME=pycryptodome
PACKAGE_VERSION=${1:-v4.3.0}
PACKAGE_URL=https://github.com/Legrandin/pycryptodome
PACKAGE_DIR=pycryptodome
CURRENT_DIR=$(pwd)

# Install required dependencies
yum install -y git python3.12 python3.12-devel python3.12-pip \
    gcc-toolset-13 gcc-toolset-13-gcc make

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:${LD_LIBRARY_PATH:-}

python3.12 -m pip install --upgrade pip setuptools wheel build

# Clone the repository (upstream tags are prefixed with 'v')
cd "${CURRENT_DIR}"
if [[ ! -d "${PACKAGE_DIR}" ]]; then
    git clone "${PACKAGE_URL}"
fi
cd "${PACKAGE_DIR}"
git checkout "v${PACKAGE_VERSION#v}"

# Install test dependencies
python3.12 -m pip install -r requirements-test.txt

# Build and install
if ! python3.12 -m pip install .; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 1
fi

# Run the self tests against the installed build, from outside the source tree
# so the unbuilt Crypto package in the checkout is not imported.
cd "${CURRENT_DIR}"
if ! python3.12 -m Crypto.SelfTest; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Both_Install_and_Test_Success"
    exit 0
fi
