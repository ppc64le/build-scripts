#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pydantic-core
# Version       : core-v2.46.4
# Source repo   : https://github.com/pydantic/pydantic.git
# Tested on     : UBI:9.6
# Language      : Python
# Ci-Check  : True
# Script License: MIT License
# Maintainer    : Vrusha Naik <Vrusha.Naik@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
set -e

# Variables
PACKAGE_NAME=pydantic-core
PACKAGE_VERSION=${1:-core-v2.46.4}
PACKAGE_URL=https://github.com/pydantic/pydantic.git
PACKAGE_DIR=pydantic/pydantic-core

# Install dependencies
yum install -y git python3 python3-devel.ppc64le gcc-toolset-13 make wget sudo cmake
pip install "pytest<9"

export PATH=$PATH:/usr/local/bin/
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)
SOURCE=Github

# Install rust
curl https://sh.rustup.rs -sSf | sh -s -- -y
source "$HOME/.cargo/env"

# Clone the repo
git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION

# Install the package
if ! python3 -m pip install ./; then
    echo "------------------$PACKAGE_NAME:install_fails------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Install_Failed"
    exit 1
fi

pip3 install hypothesis pytest-timeout inline_snapshot pytest-benchmark jsonschema pytest_examples dirty_equals pytz rich faker pytest-mock eval_type_backport typing_inspection pytest-run-parallel

test_status=1
# Run pytest if any matching test files found
if ls */test_*.py > /dev/null 2>&1 && [ $test_status -ne 0 ]; then
    echo "Running pytest..."
    (python3 -m pytest --ignore=tests/test_docstrings.py --ignore=tests/validators/test_allow_partial.py) && test_status=0 || test_status=$?
fi

# Final test result output
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