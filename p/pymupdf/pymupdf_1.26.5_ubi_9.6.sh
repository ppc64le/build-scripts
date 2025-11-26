#!/bin/bash -ex
# ----------------------------------------------------------------------------
# Package        : pymupdf
# Version        : 1.26.5
# Source repo    : https://github.com/pymupdf/PyMuPDF
# Tested on      : UBI 9.6
# Language       : Python
# Travis-Check   : false
# Maintainer     : Adarsh Agrawal <adarsh.agrawal1@ibm.com>
# Script License : Apache License, Version 2 or later
#
# Disclaimer     : This script has been tested in root mode on the specified
#                  platform and package version. Functionality with newer
#                  versions of the package or OS is not guaranteed.
# ----------------------------------------------------------------------------

# Variables
PACKAGE_NAME="PyMuPDF"
PACKAGE_ORG="pymupdf"
PACKAGE_VERSION=${1:-1.26.5}
PACKAGE_URL="https://github.com/${PACKAGE_ORG}/${PACKAGE_NAME}.git"
PACKAGE_DIR=pymupdf

# Install dependencies
echo "Installing required packages..."
yum install -y git wget gcc-toolset-13 gcc gcc-c++ python3.12 python3.12-devel python3.12-pip clang-libs zlib-devel libjpeg-devel glib2-devel libxml2-devel libxslt-devel


[ ! -L /usr/lib64/libclang.so ] && ln -s /usr/lib64/libclang.so.20.1 /usr/lib64/libclang.so
python3.12 -m pip install --upgrade pip setuptools wheel build
pip3.12 install pytest tox nox pylint psutil pymupdf-fonts flake8 codespell
pip3.12 install pillow --index-url https://wheels.developerfirst.ibm.com/ppc64le/linux 

export PATH=$PATH:/usr/local/bin/
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)
SOURCE=Github

# ---------------------------
# Clone and Prepare Repository
# ---------------------------
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

# pip3.12 install dist/pymupdf-*.whl

# Install the package
if ! python3.12 -m pip install ./; then
    echo "------------------$PACKAGE_NAME:install_fails------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Install_Failed"
    exit 1
fi

# Build the wheel
python3.12 -m build --wheel

# ------------------ Unified Test Execution Block ------------------

test_status=1  # 0 = success, non-zero = failure

# Run pytest if any matching test files found
if ls */test_*.py > /dev/null 2>&1 && [ $test_status -ne 0 ]; then
    echo "Running pytest..."
    (python3.12 -m pytest) && test_status=0 || test_status=$?
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
