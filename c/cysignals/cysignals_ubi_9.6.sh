#!/bin/bash -e

# -----------------------------------------------------------------------------
#
# Package          : cysignals
# Version          : 1.11.4
# Source repo      : https://github.com/sagemath/cysignals
# Tested on        : UBI:9.6
# Language         : Python, C
# Ci-Check         : True
# Script License   : GNU Lesser General Public License v3.0
# Maintainer       : Vrusha Naik <Vrusha.Naik@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions.
#
# -----------------------------------------------------------------------------

set -ex

# Variables
PACKAGE_NAME=cysignals
PACKAGE_VERSION=${1:-1.11.4}
PACKAGE_URL=https://github.com/sagemath/cysignals
PACKAGE_DIR=cysignals

# Install dependencies
yum install -y \
    git \
    python3 \
    python3-devel.ppc64le \
    gcc-toolset-13 \
    make \
    wget \
    sudo \
    cmake \
    autoconf \
    automake \
    libtool

pip3 install pytest tox nox cython

export PATH=$PATH:/usr/local/bin/
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)
SOURCE=Github

# Clone the package
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

# Install the package
if ! python3 -m pip install .; then
    echo "------------------$PACKAGE_NAME:install_fails------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Install_Failed"
    exit 1
fi

# ------------------ Unified Test Execution Block ------------------

test_status=1  # 0 = success, non-zero = failure
tests_found=0

# Detect tests (directories or files)
if find . \( -type d -name "tests" -o -name "test_*.py" \) | grep -q .; then
    tests_found=1
fi

# Run pytest if tests are found
if [ $tests_found -eq 1 ] && [ $test_status -ne 0 ]; then
    echo "Running pytest (auto-detected tests)..."
    (python3 -m pytest -v) && test_status=0 || test_status=$?
fi

# Run tox if available and pytest didnt run/pass
if [ -f "tox.ini" ] && [ $test_status -ne 0 ]; then
    echo "Running tox..."
    (python3 -m tox -e py39) && test_status=0 || test_status=$?
fi

# Run nox if available and still failing
if [ -f "noxfile.py" ] && [ $test_status -ne 0 ]; then
    echo "Running nox..."
    (python3 -m nox) && test_status=0 || test_status=$?
fi

# If no tests found at all → mark as PASS
if [ $tests_found -eq 0 ]; then
    echo "No tests found, marking as PASS"
    test_status=0
fi

# Final result
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
