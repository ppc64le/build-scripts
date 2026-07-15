#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : cykhash
# Version       : v2.0.0
# Source repo   : https://github.com/realead/cykhash
# Tested on     : UBI:9.3
# Language      : Python
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Rosman Carino <rcarino@ibm.com>
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
PACKAGE_NAME=cykhash
PACKAGE_VERSION=${1:-v2.0.0}
PACKAGE_URL=https://github.com/realead/cykhash
PACKAGE_DIR=cykhash

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)
SOURCE=Github

# Install system dependencies
yum install -y git python3 python3-devel gcc-toolset-13 make wget sudo

export PATH=$PATH:/usr/local/bin/
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

# Install Python build and test dependencies
# numpy<1.24 is compatible with v2.0.0 tests (which use np.object, removed in 1.24),
# but numpy<1.24 cannot build on Python 3.12+ because pkg_resources.ImpImporter was
# removed in Python 3.12. On Python 3.12+ install numpy>=2.0 instead.
PYTHON_MINOR=$(python3 -c "import sys; print(sys.version_info.minor)")
PYTHON_MAJOR=$(python3 -c "import sys; print(sys.version_info.major)")

if [ "$PYTHON_MAJOR" -gt 3 ] || [ "$PYTHON_MINOR" -ge 12 ]; then
    NUMPY_VERSION="numpy>=2.0"
else
    NUMPY_VERSION="numpy<1.24"
fi

pip3 install \
    "setuptools" \
    "wheel" \
    "Cython>=0.28" \
    pytest \
    "$NUMPY_VERSION"

# Clone the repo (or reuse existing directory)
if [ -d "$PACKAGE_DIR" ]; then
    cd "$PACKAGE_DIR" || exit
else
    if ! git clone "$PACKAGE_URL" "$PACKAGE_DIR"; then
        echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Clone_Fails"
        exit 1
    fi
    cd "$PACKAGE_DIR" || exit
    git checkout "$PACKAGE_VERSION" || exit
fi

# On Python 3.12+, numpy>=2.0 is installed. Patch all v2.0.0 test files to replace
# the three removed NumPy aliases before running the suite:
#   np.object  -> np.object_   (removed in NumPy 1.24)
#   np.int     -> np.int_      (removed in NumPy 1.24)
#   np.in1d    -> np.isin      (removed in NumPy 2.0)
if [ "$PYTHON_MAJOR" -gt 3 ] || [ "$PYTHON_MINOR" -ge 12 ]; then
    find tests/unit_tests/ -name "*.py" | xargs sed -i \
        -e 's/np\.object\([^_]\)/np.object_\1/g' \
        -e 's/np\.int\([^_0-9a-zA-Z]\)/np.int_\1/g' \
        -e 's/np\.in1d/np.isin/g'
fi

# Install the package (builds Cython extensions)
if ! python3 -m pip install ./; then
    echo "------------------$PACKAGE_NAME:install_fails------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Install_Failed"
    exit 1
fi

# Run tests
if ! python3 -m pytest tests/unit_tests/; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_and_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Pass | Both_Install_and_Test_Success"
    exit 0
fi