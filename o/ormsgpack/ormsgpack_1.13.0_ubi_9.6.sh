#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : ormsgpack
# Version          : 1.13.0
# Source repo      : https://github.com/aviramha/ormsgpack
# Tested on        : UBI:9.6
# Language         : Rust, Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vinit Janbandhu <Vinit.Janbandhu@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

set -e

PACKAGE_NAME=ormsgpack
PACKAGE_VERSION=${1:-1.13.0}
PACKAGE_URL=https://github.com/aviramha/ormsgpack
PACKAGE_DIR=ormsgpack
CURRENT_DIR=$(pwd)
IBM_WHEELS="https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/"
IBM_WHEELS_HOST="wheels.developerfirst.ibm.com"

# System dependencies (requires-python >= 3.11)
yum install -y git python3.12 python3.12-devel python3.12-pip \
    gcc-toolset-13 gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ make openssl-devel

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:${LD_LIBRARY_PATH:-}

# Rust toolchain (the repo's rust-toolchain.toml pins the exact version and rustup fetches it)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
source "$HOME/.cargo/env"

# Build tool (pyproject: maturin>=1.0,<2.0)
python3.12 -m pip install --upgrade pip setuptools wheel "maturin>=1.0,<2.0"

# Test dependencies (dev + numpy from pyproject dependency-groups); IBM wheel index avoids Rust builds
python3.12 -m pip install --trusted-host "${IBM_WHEELS_HOST}" \
    --extra-index-url "${IBM_WHEELS}" --prefer-binary \
    pytest msgpack numpy pydantic python-dateutil pytz tzdata pendulum

# Clone source (upstream tags have no 'v' prefix; accept both forms)
cd "${CURRENT_DIR}"
if [[ ! -d "${PACKAGE_DIR}" ]]; then
    git clone "${PACKAGE_URL}"
fi
cd "${PACKAGE_DIR}"
git checkout "${PACKAGE_VERSION#v}"

# Build and install
if ! python3.12 -m pip install . --no-build-isolation; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Sources live under python/, so pytest from the repo root tests the installed build
if ! python3.12 -m pytest tests -p no:cacheprovider; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
