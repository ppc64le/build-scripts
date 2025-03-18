#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : outlines-core
# Version          : 0.1.26

# Source repo      : https://github.com/dottxt-ai/outlines-core
# Tested on        : UBI 9.3
# Language         : Python, Rust
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Puneet Sharma <Puneet.Sharma21@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on the given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact the "Maintainer" of this script.
# -----------------------------------------------------------------------------

PACKAGE_NAME=outlines-core
PACKAGE_URL=https://github.com/dottxt-ai/outlines-core.git
PACKAGE_VERSION=${1:-0.1.26}
PYTHON_VERSION=${PYTHON_VERSION:-3.11}

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

# Install dependencies
echo "Installing dependencies..."
dnf update -y
dnf install -y git gcc-toolset-13 make python${PYTHON_VERSION} python${PYTHON_VERSION}-devel \
               python${PYTHON_VERSION}-pip openssl openssl-devel
source /opt/rh/gcc-toolset-13/enable

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env


# Clone the repository
if [ -d "$PACKAGE_NAME" ]; then
    rm -rf $PACKAGE_NAME
    echo "$PACKAGE_NAME | $PACKAGE_VERSION | $OS_NAME | GitHub | Removed existing package if any"
fi

# Cloning the repository from remote to local
if [ -z $PACKAGE_SOURCE_DIR ]; then
  git clone $PACKAGE_URL
  cd $PACKAGE_NAME  
else  
  cd $PACKAGE_SOURCE_DIR
fi

git checkout $PACKAGE_VERSION

# Configure OpenSSL environment variables
export OPENSSL_DIR=/usr
export OPENSSL_LIB_DIR=/usr/lib64
export OPENSSL_INCLUDE_DIR=/usr/include

# Build the project
echo "Building Outlines Core..."
python${PYTHON_VERSION} -m pip install --upgrade pip setuptools wheel pytest pydantic

if ! python${PYTHON_VERSION} -m pip install -e .; then
    echo "------------------$PACKAGE_NAME:Build_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail |  Build_fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:Build_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Build_Success"
fi

# Define possible test file paths
OLD_TEST_PATH="tests/fsm/test_json_schema.py"
NEW_TEST_PATH="tests/test_json_schema.py"

# Determine which test file exists
if [ -f "$OLD_TEST_PATH" ]; then
    TEST_PATH="$OLD_TEST_PATH"
elif [ -f "$NEW_TEST_PATH" ]; then
    TEST_PATH="$NEW_TEST_PATH"
else
    echo "Error: Test file not found in expected locations."
    exit 1
fi

# Run Python tests with the correct path
if ! python${PYTHON_VERSION} -m pytest "$TEST_PATH"; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:both_install_and_test_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
