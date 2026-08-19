#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package           : faiss-cpu
# Version           : 1.9.0.post1
# Source repo       : https://github.com/faiss-wheels/faiss-wheels
# Tested on         : UBI 10.2
# Language          : C++, Python
# Ci-Check          : True
# Script License    : Apache License Version 2.0
# Maintainer        : Varsha Kumar <varsha.kumar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such cases, please
#             contact the "Maintainer" of this script.
#

set -e
PACKAGE_NAME=faiss-cpu
PACKAGE_DIR=faiss-wheels
PACKAGE_VERSION=${1:-1.9.0.post1}
PACKAGE_URL=https://github.com/faiss-wheels/faiss-wheels.git
SOURCE_ROOT="$(pwd)"

echo "Installing dependencies..."
dnf update -y
dnf install -y  \
     python3 python3-devel python3-pip \
     openblas-devel make gcc g++ cmake git automake autoconf

echo "Upgrading Python tools..."
python3 -m ensurepip --upgrade
python3 -m pip install --upgrade setuptools wheel build uv

# Detect the active Python version FIRST so it drives everything below
CP=$(python3 -c "import sysconfig; print(sysconfig.get_config_var('py_version_nodot'))")
PY_MAJOR_MINOR=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")

git clone --recursive ${PACKAGE_URL}
cd ${PACKAGE_DIR}

# Allow the detected Python version in uv's environment filter
echo -e "\n[tool.uv]\nenvironments = [\"python_version == '3.12' or python_version == '3.13' or python_version == '3.14'\"]" >> pyproject.toml

# Pin uv to the same Python that is active on this system
uv python pin ${PY_MAJOR_MINOR}

sed -i "s/.version=.*/version='"$PACKAGE_VERSION"',/" third-party/faiss/faiss/python/setup.py
export INDEX_URL_DEVPY="https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple"
sed -i '/^\[project\]/,/^$/ {s/version = "[^"]*"/version = "'"$PACKAGE_VERSION"'"/}' pyproject.toml

uv build --wheel --config-setting wheel.py-api=cp$CP --extra-index-url $INDEX_URL_DEVPY

WHEEL_PATH=$(find dist -maxdepth 1 -type f -name 'faiss_cpu-*.whl' | head -1)

if [ -z "$WHEEL_PATH" ]; then
    echo "------------------$PACKAGE_NAME:Wheel not found------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Wheel_Not_Found"
    exit 1
fi

echo "Installing wheel: $WHEEL_PATH"

if ! python3 -m pip install "$WHEEL_PATH"; then
    echo "------------------$PACKAGE_NAME:Failed to install wheel------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 1
fi

# Run tests
python3 -m pip install scipy==1.17.0 sentence-transformers --extra-index-url $INDEX_URL_DEVPY

# find test case called app.py
TEST_PATH=$(find "${SOURCE_ROOT}" -name app.py | head -1)
if [ -z "${TEST_PATH}" ]; then
    echo "ERROR: test case not found"
    exit 1
fi
if ! (python3 $TEST_PATH); then
     echo "--------------------$PACKAGE_NAME:Install_success_but_test_fails--------------------"
     echo "$PACKAGE_URL $PACKAGE_NAME"
     echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
     exit 2
else
     echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
     echo "$PACKAGE_URL $PACKAGE_NAME"
     echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Import_Success"
     exit 0
fi