#!/bin/bash -ex
# ----------------------------------------------------------------------------
# Package        : polars_ds_extension
# Version        : v0.11.0
# Source repo    : https://github.com/abstractqqq/polars_ds_extension.git
# Tested on      : UBI 9.8
# Language       : Python, Rust
# Ci-Check       : True
# Maintainer     : Pratik Tonage <Pratik.Tonage@ibm.com>
# Script License : Apache License, Version 2.0 or later
#
# Disclaimer     : This script has been tested in root mode on the specified
#                  platform and package version. Functionality with newer
#                  versions of the package or OS is not guaranteed.
# ----------------------------------------------------------------------------

# ---------------------------
# Configuration
# ---------------------------
PACKAGE_NAME="polars_ds_extension"
PACKAGE_VERSION=${1:-v0.11.0}
PACKAGE_URL="https://github.com/abstractqqq/polars_ds_extension.git"
BUILD_HOME="$(pwd)"
DEVPI_INDEX="https://wheels.developerfirst.ibm.com/ppc64le/linux"

# ---------------------------
# Dependency Installation
# ---------------------------

yum install -y python3.12 python3.12-pip python3.12-devel make
yum -y install \
    git curl-minimal ca-certificates gcc gcc-c++ cmake openssl-devel \
    pkgconf-pkg-config zlib-devel libffi-devel \
    graphviz gfortran openblas-devel

# Install Rust
curl --proto '=https' --tlsv1.3 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
source "$HOME/.cargo/env"
rustc --version && cargo --version
	  
# ---------------------------
# Clone Repository
# --------------------------- 
cd "${BUILD_HOME}"
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Install Python build tools
python3.12 -m pip install --upgrade pip 
python3.12 -m pip install maturin pytest setuptools wheel build 

# ---------------------------
# Build
# ---------------------------
if ! maturin build --release; then
    echo "------------------$PACKAGE_NAME:Build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

export POLARSDS_WHEEL="$(find target/wheels -maxdepth 1 -type f -name '*.whl' | head -n 1)"
test -f ${POLARSDS_WHEEL}
cp "$POLARSDS_WHEEL" "$BUILD_HOME/"

# ----------------------------------------------
# Install package and runtime/test dependencies
# ----------------------------------------------
python3.12 -m pip install "$POLARSDS_WHEEL" 
python3.12 -m pip install --prefer-binary --no-cache-dir --extra-index-url=${DEVPI_INDEX} numpy pandas scipy scikit-learn pyarrow statsmodels "polars==1.44.2"
python3.12 -m pip install jupyter ipython ipykernel nbconvert typing_extensions pytest-benchmark category_encoders copent altair great-tables astropy scikit-survival
python3.12 -m pip install -r docs/requirements-docs.txt

# ---------------------------
# Test
# ---------------------------
# 1 test (test_random_functions_in_streaming) is deselected because it's in parity with x86.

if ! python3.12 -m pytest tests/test_* -v --deselect tests/test_many.py::test_random_functions_in_streaming; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi

# ---------------------------
# Conclude
# ---------------------------
set +ex
echo "Complete: Build and Test successful!"
echo "connectorx wheel available at [$POLARSDS_WHEEL]"
