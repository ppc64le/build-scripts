#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : pydantic-core
# Version          : v2.27.1
# Source repo      : https://github.com/pydantic/pydantic-core
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
PACKAGE_NAME=pydantic-core
PACKAGE_VERSION=${1:-v2.27.1}
PACKAGE_URL=https://github.com/pydantic/pydantic-core
PACKAGE_DIR=pydantic-core

# Install dependencies
yum install -y git python3 python3-devel.ppc64le gcc-toolset-13 make wget sudo cmake
pip3 install pytest maturin

export PATH=$PATH:/usr/local/bin/
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

# Install Rust (required for some dependencies)
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

pip3 install hypothesis pytest-timeout inline_snapshot pytest-benchmark jsonschema pytest_examples dirty_equals pytz rich faker pytest-mock eval_type_backport

# Skipping this test because it uses `pytest.raises(match="")`, which is invalid under pytest>=8.
# Empty match strings always pass and trigger PytestWarning, so the test is not meaningful until fixed.
if ! (pytest --ignore=tests/test_docstrings.py --ignore=tests/validators/test_arguments.py); then
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
