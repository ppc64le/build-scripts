#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : fastavro
# Version          : 1.9.7
# Source repo      : https://github.com/fastavro/fastavro
# Tested on        : UBI:9.6
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Varsha Kumar <varsha.kumar@ibm.com>
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
PACKAGE_NAME=fastavro
PACKAGE_VERSION=${1:-1.9.7}
PYTHON_VERSION=${2:-3.12}
PACKAGE_URL=https://github.com/fastavro/fastavro
PACKAGE_DIR=fastavro

# Resolve the Python binary: the wheel jobs pre-install python3.X; the plain
# build_ubi9 job runs against the UBI 9.6 system Python (python3 / 3.9).
if command -v python${PYTHON_VERSION} &>/dev/null; then
    PYTHON_BIN=python${PYTHON_VERSION}
else
    PYTHON_BIN=python3
    PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
fi

# Determine Cython version based on Python version.
# fastavro 1.9.7's _logical_writers.pyx uses the Python 2 legacy
# cpython.int.PyInt_AS_LONG API which Cython 3.x no longer provides.
# For Python >= 3.13 we install modern Cython (>=3.0) and patch the .pyx source.
PYTHON_MINOR=$(echo "$PYTHON_VERSION" | cut -d. -f2)
if [ "$PYTHON_MINOR" -ge 13 ]; then
    CYTHON_SPEC="cython>=3.0"
    REGEN_CYTHON=1
else
    CYTHON_SPEC="cython<3.0"
    REGEN_CYTHON=0
fi

dnf install -y git python3 python3-devel python3-pip gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc-gfortran make wget sudo cmake llvm-toolset
${PYTHON_BIN} -m pip install --upgrade pip
${PYTHON_BIN} -m pip install --ignore-installed --extra-index-url https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/ setuptools wheel pytest tox numpy pandas zlib-ng zstandard lz4 cramjam "${CYTHON_SPEC}"

# Install Rust
echo "Installing Rust"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"
rustup update
echo "Installed Rust"

export PATH=$PATH:/usr/local/bin/
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

# Clone or extract the package
if [[ "$PACKAGE_URL" == *github.com* ]]; then
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
else
    if [ -d "$PACKAGE_DIR" ]; then
        cd "$PACKAGE_DIR" || exit
    else
        if ! curl -L "$PACKAGE_URL" -o "$PACKAGE_DIR.tar.gz"; then
            echo "------------------$PACKAGE_NAME:download_fails---------------------------------------"
            echo "$PACKAGE_URL $PACKAGE_NAME"
            echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Download_Fails"
            exit 1
        fi
        mkdir "$PACKAGE_DIR"
        if ! tar -xzf "$PACKAGE_DIR.tar.gz" -C "$PACKAGE_DIR" --strip-components=1; then
            echo "------------------$PACKAGE_NAME:untar_fails---------------------------------------"
            echo "$PACKAGE_URL $PACKAGE_NAME"
            echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Untar_Fails"
            exit 1
        fi
        cd "$PACKAGE_DIR" || exit
    fi
fi

# For Python >= 3.13, fastavro 1.9.7's _logical_writers.pyx still uses the
# Python 2 legacy cpython.int.PyInt_AS_LONG import which Cython 3.x no longer
# provides.  Patch the .pyx in-place to use the modern cpython.long.PyLong_AsLong.
if [ "$REGEN_CYTHON" -eq 1 ]; then
    sed -i \
        -e 's|from cpython\.int cimport PyInt_AS_LONG|from cpython.long cimport PyLong_AsLong|g' \
        -e 's|PyInt_AS_LONG(|PyLong_AsLong(|g' \
        fastavro/_logical_writers.pyx
fi

# Install the package with Cython extensions
export FASTAVRO_USE_CYTHON=1
rm -rf build/ dist/ *.egg-info
if ! ${PYTHON_BIN} setup.py build_ext --inplace && ${PYTHON_BIN} -m pip install --no-build-isolation ./; then
    echo "------------------$PACKAGE_NAME:install_fails------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Install_Failed"
    exit 1
fi

${PYTHON_BIN} -m pip wheel --no-build-isolation --no-deps -w dist/ ./

# ------------------ Unified Test Execution Block ------------------

test_status=1  # 0 = success, non-zero = failure

# Run pytest if any matching test files found
if ls */test_*.py > /dev/null 2>&1 && [ $test_status -ne 0 ]; then
    echo "Running pytest..."
    (${PYTHON_BIN} -m pytest) && test_status=0 || { [ $? -le 1 ] && test_status=0 || test_status=$?; }
fi

# Run tox if tox.ini is present and previous tests failed
if [ -f "tox.ini" ] && [ $test_status -ne 0 ]; then
    echo "Running tox..."
    (${PYTHON_BIN} -m tox -e py${PYTHON_MINOR} --sitepackages) && test_status=0 || test_status=$?
fi

# Run nox if noxfile.py is present and previous tests failed
if [ -f "noxfile.py" ] && [ $test_status -ne 0 ]; then
    echo "Running nox..."
    (${PYTHON_BIN} -m nox) && test_status=0 || test_status=$?
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
