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
dnf install -y git gcc gcc-c++ make python${PYTHON_VERSION} python${PYTHON_VERSION}-devel \
               python${PYTHON_VERSION}-pip openssl openssl-devel rust cargo

dnf install -y https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/Packages/centos-gpg-keys-9.0-24.el9.noarch.rpm \
https://mirror.stream.centos.org/9-stream/BaseOS/`arch`/os/Packages/centos-stream-repos-9.0-24.el9.noarch.rpm \
https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os
dnf config-manager --set-enabled crb

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

# Run Python tests
if ! python${PYTHON_VERSION} -m pytest tests/fsm/test_json_schema.py; then
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

