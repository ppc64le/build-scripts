#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : SudachiPy
# Version          : v0.7.0
# Source repo      : https://github.com/WorksApplications/sudachi.rs
# Tested on        : UBI:9.8
# Language         : Rust, Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Ira Pandey <ira.pandey2001@gmail.com>
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
PACKAGE_NAME=SudachiPy
PACKAGE_VERSION=${1:-v0.7.0}
PACKAGE_URL=https://github.com/WorksApplications/sudachi.rs
PACKAGE_DIR=sudachi.rs
WORKDIR=$(pwd)
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

# Install dependencies
yum install -y git python3.12 python3.12-devel python3.12-pip gcc-toolset-13 make

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

# Install Rust (MSRV of the python crate is 1.83)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
source "$HOME/.cargo/env"
rustc --version
cargo --version

python3.12 -m pip install --upgrade pip setuptools wheel
# Must satisfy pyproject.toml: maturin>=1.9.4,<2
python3.12 -m pip install "maturin>=1.9.4,<2"

# Clone the repo
cd "$WORKDIR"
git clone "$PACKAGE_URL" "$PACKAGE_DIR"
cd "$PACKAGE_DIR"
git checkout "$PACKAGE_VERSION"

# Build the wheel (pyproject.toml is at the repo root; the crate lives in python/)
if ! python3.12 -m pip wheel --no-cache-dir --no-deps . -w "$WORKDIR/dist"; then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
    exit 1
fi

WHEEL=$(ls "$WORKDIR"/dist/[Ss]udachi[Pp]y-*.whl | head -1)
echo "Wheel: $WHEEL"

cp "$WHEEL" "$WORKDIR/"

# Install the wheel
if ! python3.12 -m pip install "$WHEEL"; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Test dependencies. 'tokenizers' is only needed by test_pretokenizers.py,
# skip that module if no ppc64le build of it is available.
SKIP_PRETOKENIZERS=0
python3.12 -m pip install sudachidict_core
python3.12 -m pip install tokenizers || SKIP_PRETOKENIZERS=1

# Run the tests against the installed wheel (same as upstream cibuildwheel test-command)
python3.12 -c "import sudachipy; print(sudachipy.__version__)"
sudachipy --help

TEST_FAILED=0
if [ "$SKIP_PRETOKENIZERS" -eq 1 ]; then
    for t in python/tests/test_*.py; do
        [ "$(basename "$t")" = "test_pretokenizers.py" ] && continue
        python3.12 -m unittest discover -s python/tests -p "$(basename "$t")" || TEST_FAILED=1
    done
else
    python3.12 -m unittest discover -s python/tests || TEST_FAILED=1
fi

if [ "$TEST_FAILED" -ne 0 ]; then
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
