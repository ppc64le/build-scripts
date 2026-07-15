#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : asyncpg
# Version       : v0.31.0
# Source repo   : https://github.com/MagicStack/asyncpg
# Tested on     : UBI:9.6
# Language      : Python
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Varsha Kumar <varsha.kumar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Variables
PACKAGE_NAME=asyncpg
PACKAGE_VERSION=v0.31.0
PACKAGE_URL=https://github.com/MagicStack/asyncpg
PACKAGE_DIR=asyncpg

# Install dependencies
dnf install -y git python3.12 python3.12-pip python3.12-setuptools python3.12-devel gcc-toolset-13 make wget sudo cmake
python3.12 -m pip install pytest tox nox

export PATH=$PATH:/usr/local/bin/
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)
SOURCE=Github

# Install rust
if ! command -v rustc &> /dev/null
then
    wget https://static.rust-lang.org/dist/rust-1.75.0-powerpc64le-unknown-linux-gnu.tar.gz
    tar -xzf rust-1.75.0-powerpc64le-unknown-linux-gnu.tar.gz
    cd rust-1.75.0-powerpc64le-unknown-linux-gnu
    sudo ./install.sh
    export PATH=$HOME/.cargo/bin:$PATH
    rustc -V
    cargo -V
    cd ../
fi

# Clone or extract the package
if [[ "$PACKAGE_URL" == *github.com* ]]; then
    if [ -d "$PACKAGE_DIR" ]; then
        cd "$PACKAGE_DIR" || exit
    else
        if ! git clone --recurse-submodules "$PACKAGE_URL" "$PACKAGE_DIR"; then
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

# Install build dependencies (Cython required to compile asyncpg extensions)
python3.12 -m pip install --upgrade "Cython>=3.2.1,<4.0.0" "setuptools>=68.0.0" wheel

# Install the package (builds Cython/C extensions in-place)
if ! python3.12 -m pip install --no-build-isolation ./; then
    echo "------------------$PACKAGE_NAME:install_fails------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Install_Failed"
    exit 1
fi

# ------------------ Unified Test Execution Block ------------------

test_status=1  # 0 = success, non-zero = failure

# Run pytest if any matching test files found
# Note: asyncpg tests/test_record.py and tests/test__sourcecode.py do not
# require a live PostgreSQL connection and serve as a smoke test.
# For full integration tests, set PGHOST/PGPORT/PGUSER/PGPASSWORD env vars
# pointing to a running PostgreSQL instance.
if ls tests/test_*.py > /dev/null 2>&1 && [ $test_status -ne 0 ]; then
    echo "Running pytest..."
    (cd .. && python3.12 -m pytest asyncpg/tests/test__sourcecode.py -v) && test_status=0 || test_status=$?
fi

# Run tox if tox.ini is present and previous tests failed
if [ -f "tox.ini" ] && [ $test_status -ne 0 ]; then
    echo "Running tox..."
    (python3.12 -m tox -e py39) && test_status=0 || test_status=$?
fi

# Run nox if noxfile.py is present and previous tests failed
if [ -f "noxfile.py" ] && [ $test_status -ne 0 ]; then
    echo "Running nox..."
    (python3.12 -m nox) && test_status=0 || test_status=$?
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