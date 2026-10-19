#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package          : coreforecast
# Version          : v0.0.16
# Source repo      : https://github.com/Nixtla/coreforecast
# Tested on        : UBI:9.8
# Language         : Python, C++
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Mohammed Sheikh <Mohammed.Sheikh1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=coreforecast
PACKAGE_VERSION=${1:-v0.0.16}
PACKAGE_URL=https://github.com/Nixtla/coreforecast
PACKAGE_DIR=coreforecast
WORK_DIR=$(pwd)

# Installing system dependencies
dnf install -y \
    git \
    gcc \
    gcc-c++ \
    make \
    cmake \
    python3 \
    python3-devel \
    python3-pip

# Clone repository
cd ${WORK_DIR}
git clone ${PACKAGE_URL} -b ${PACKAGE_VERSION}
cd ${PACKAGE_DIR}

# Initialize submodules recursively
git submodule update --init --recursive

# make changes in pyproject.toml
sed -i 's/cmake\.verbose/build.verbose/g' pyproject.toml || true

# Install build dependencies
python3 -m pip install --upgrade pip build

# Installing dev dependencies
if ! python3 -m pip install --prefer-binary ".[dev]" pytest-codspeed --extra-index-url https://wheels.developerfirst.ibm.com/ppc64le/linux; then
    echo "------------------$PACKAGE_NAME:dependency_install_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_VERSION | GitHub | Fail | Dependency_Install_Fails"
    exit 1
fi

# Build wheel
# if ! python3 -m build --wheel --outdir /dist .; then
#     echo "------------------$PACKAGE_NAME:wheel_build_fails---------------------"
#     echo "$PACKAGE_VERSION $PACKAGE_NAME"
#     echo "$PACKAGE_NAME | $PACKAGE_VERSION | GitHub | Fail | Wheel_Build_Fails"
#     exit 1
# fi

# # Install built package wheel
# if ! python3 -m pip install --force-reinstall --no-deps /dist/*.whl; then
#     echo "------------------$PACKAGE_NAME:install_fails---------------------"
#     echo "$PACKAGE_VERSION $PACKAGE_NAME"
#     echo "$PACKAGE_NAME | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
#     exit 1
# fi

# Validation / Test
if ! pytest tests/; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_VERSION | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_and_test_success-------------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_VERSION | GitHub | Pass | Install_and_Test_Success"
    exit 0
fi