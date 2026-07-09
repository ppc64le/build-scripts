#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package          : bcrypt
# Version          : 4.0.1
# Source repo      : https://github.com/pyca/bcrypt
# Tested on        : UBI:9.6
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Varsha Kumar <varsha.kumar@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------


# Variables
PACKAGE_NAME=bcrypt
PACKAGE_VERSION=${1:-4.0.1}
PACKAGE_URL=https://github.com/pyca/bcrypt
PACKAGE_DIR=bcrypt
WORK_DIR=$(pwd)

# Install necessary system dependencies
dnf install -y git wget python3.12 python3.12-devel python3.12-pip zip unzip gcc gcc-c++

# Install rust
curl https://sh.rustup.rs -sSf | sh -s -- -y
source "$HOME/.cargo/env"  # Update environment variables to use Rust

git clone -b $PACKAGE_VERSION $PACKAGE_URL
cd bcrypt

pip3.12 install --upgrade requests
pip3.12 install setuptools tox setuptools-rust

# Install and save wheel to dist/
if ! (pip3.12 install .) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Build and save wheel to dist/
pip3.12 wheel . --no-deps -w dist/

# Note: A 'no-ctracer' CoverageWarning may appear during tox execution on ppc64le.
# This is expected — the coverage C extension is not available for this architecture.
# The Python tracer is used as a fallback and produces identical results. Safe to ignore.
export COVERAGE_CORE=pytrace

# Run tests
if !(tox -e py3 2>&1 | grep -v "no-ctracer"); then
    echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi