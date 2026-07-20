#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : microsoft-authentication-extensions-for-python
# Version          : 1.2.0
# Source repo      : https://github.com/AzureAD/microsoft-authentication-extensions-for-python
# Tested on     : UBI:9.6
# Language      : Python
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -ex
# Variables
PACKAGE_NAME=microsoft-authentication-extensions-for-python
PACKAGE_VERSION=${1:-1.2.0}
PACKAGE_URL=https://github.com/AzureAD/microsoft-authentication-extensions-for-python
PACKAGE_DIR=microsoft-authentication-extensions-for-python

# Install dependencies
yum install -y git python3 python3-devel.ppc64le gcc-toolset-13 
pip3 install pytest 

export PATH=$PATH:/usr/local/bin/
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

curl https://sh.rustup.rs -sSf | sh -s -- -y
source "$HOME/.cargo/env"

# Clone the repo
git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION

if ! python3 -m pip install -e .; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

pip3 install maturin

# These tests require libsecret (gi.repository.Secret) which is an optional,
# platform-specific dependency. It is not available in minimal RHEL/EL CI
# environments (and many container images). Since msal_extensions treats
# libsecret as best-effort, we skip these tests when the dependency is missing
# to avoid false CI failures.
if ! (pytest -k "not persistence_builder and not libsecret_persistence"); then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
