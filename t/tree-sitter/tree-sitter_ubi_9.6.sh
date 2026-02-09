#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : tree-sitter
# Version          : v0.24.0
# Source repo      : https://github.com/tree-sitter/py-tree-sitter
# Tested on        : UBI 9.6
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Adarsh Agrawal <adarsh.agrawal1@ibm.com>
#
# Disclaimer       : This sacript has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
set -e

# Variables
PACKAGE_NAME=tree-sitter
PACKAGE_VERSION=${1:-v0.24.0}
PACKAGE_URL=https://github.com/tree-sitter/py-tree-sitter
PACKAGE_DIR=py-tree-sitter
BUILD_HOME=$(pwd)

# Install dependencies
yum install -y git gcc gcc-c++ python3.12 python3.12-devel.ppc64le gcc-toolset-13 make wget sudo cmake python3.12-pip
python3.12 -m pip install build pytest wheel
export PATH=$PATH:/usr/local/bin/
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)
SOURCE=Github

# Install rust
if ! command -v rustc &> /dev/null
then
    wget https://static.rust-lang.org/dist/rust-1.88.0-powerpc64le-unknown-linux-gnu.tar.gz
    tar -xzf rust-1.88.0-powerpc64le-unknown-linux-gnu.tar.gz
    cd rust-1.88.0-powerpc64le-unknown-linux-gnu
    sudo ./install.sh
    export PATH=$HOME/.cargo/bin:$PATH
    rustc -V
    cargo -V
    cd ../
fi

# Install tree-sitter header
TREE_SITTER_C_VERSION=v0.24.0
git clone https://github.com/tree-sitter/tree-sitter-c
cd tree-sitter-c
git checkout $TREE_SITTER_C_VERSION
mkdir -p /usr/include/tree_sitter/
cp src/tree_sitter/*.h /usr/include/tree_sitter/
cd $BUILD_HOME

TREE_SITTER_VERSION=v0.25.0
git clone https://github.com/tree-sitter/tree-sitter.git
cd tree-sitter
make
git checkout $TREE_SITTER_VERSION
make install
cd $BUILD_HOME

# Build and Install tree-sitter-html
TREE_SITTER_HTML_VERSION=v0.23.2
git clone https://github.com/tree-sitter/tree-sitter-html.git
cd tree-sitter-html
git checkout $TREE_SITTER_HTML_VERSION
pip3.12 install .
cd $BUILD_HOME

# Build and Install tree-sitter-json
TREE_SITTER_JSON_VERSION=v0.24.8
git clone https://github.com/tree-sitter/tree-sitter-json.git
cd tree-sitter-json
git checkout $TREE_SITTER_JSON_VERSION
pip3.12 install .
cd $BUILD_HOME

# Build and Install tree-sitter-python
TREE_SITTER_PYTHON_VERSION=v0.23.6
git clone https://github.com/tree-sitter/tree-sitter-python.git
cd tree-sitter-python
git checkout $TREE_SITTER_PYTHON_VERSION
pip3.12 install .
cd $BUILD_HOME

# Build and Install tree-sitter-javascript
TREE_SITTER_JAVASCRIPT_VERSION=v0.23.1
git clone https://github.com/tree-sitter/tree-sitter-javascript.git
cd tree-sitter-javascript
git checkout $TREE_SITTER_JAVASCRIPT_VERSION
pip3.12 install .
cd $BUILD_HOME

# Build and Install tree-sitter-rust
TREE_SITTER_RUST_VERSION=v0.23.2
git clone https://github.com/tree-sitter/tree-sitter-rust.git
cd tree-sitter-rust
git checkout $TREE_SITTER_RUST_VERSION
pip3.12 install .
cd $BUILD_HOME

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
git submodule update --init --recursive

# Install the package
if ! python3.12 -m pip install -v -e '.[tests]'; then
    echo "------------------$PACKAGE_NAME:install_fails------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Install_Failed"
    exit 1
fi

# ------------------ Unified Test Execution Block ------------------

test_status=1  # 0 = success, non-zero = failure

# Run tests if test dir is present and previous tests failed
if [ -d "./tests" ] && [ $test_status -ne 0 ]; then
    echo "Running binding tests..."
    python3.12 -m unittest discover && test_status=0 || test_status=$?
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
