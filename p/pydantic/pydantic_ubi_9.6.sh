#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : pydantic
# Version          : v2.10.3
# Source repo      : https://github.com/pydantic/pydantic
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
PACKAGE_NAME=pydantic
PACKAGE_VERSION=${1:-v2.10.3}
PACKAGE_URL=https://github.com/pydantic/pydantic
PACKAGE_DIR=pydantic

# Install dependencies
yum install -y git python3 python3-devel.ppc64le gcc-toolset-13 make wget sudo cmake
# Downgrading pytest due to pytest 9.x incompatibility for test_deprecated_fields.py
python3 -m pip install "pytest<9" hatchling
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

# Pre-install pydantic-core from PyPI wheel to avoid source compilation.
# Without this, pip builds pydantic-core from source using the bundled PyO3,
# which caps at Python 3.13 for versions prior to pydantic v2.13.0.
PYDANTIC_CORE_VERSION=$(grep -oP "pydantic-core==\K[0-9]+\.[0-9]+\.[0-9]+" pyproject.toml | head -1)
python -m pip install "pydantic-core==${PYDANTIC_CORE_VERSION}" hatch-fancy-pypi-readme

if ! python -m pip install -e . --no-deps; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

pip3 install pytest-benchmark jsonschema pytest_examples dirty_equals pytz rich faker pytest-mock eval_type_backport pytest-run-parallel hypothesis pytest-timeout inline-snapshot black==24.10.0
# Deselect test_missing_sentinel_pickle for v2.12.0–v2.13.3: those versions mark it
# xfail(strict=True) unconditionally, but newer typing_extensions makes it pass → XPASS hard fail.
# The fix landed in v2.13.4.
PYTEST_DESELECT=""
VERSION_CLEAN=$(echo "$PACKAGE_VERSION" | sed 's/^v//')
MAJOR=$(echo "$VERSION_CLEAN" | cut -d. -f1)
MINOR=$(echo "$VERSION_CLEAN" | cut -d. -f2)
PATCH=$(echo "$VERSION_CLEAN" | cut -d. -f3)
if [ "$MAJOR" -eq 2 ] && \
   { [ "$MINOR" -eq 12 ] || { [ "$MINOR" -eq 13 ] && [ "$PATCH" -le 3 ]; }; }; then
    PYTEST_DESELECT="--deselect tests/test_missing_sentinel.py::test_missing_sentinel_pickle"
fi

if ! (pytest $PYTEST_DESELECT); then
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