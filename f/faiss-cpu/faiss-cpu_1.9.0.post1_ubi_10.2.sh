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
SOURCE_ROOT="$(cd "$(dirname "$0")" && pwd)"

# Resolve app.py to an absolute path now, before any cd into subdirectories.
# Three execution contexts:
#   1. validate_builds_currency.py (direct): $0 is the real script path,
#      SOURCE_ROOT already points to f/faiss-cpu/ — use it directly.
#   2. create_wheel_wrapper.sh: script is copied to temp_build_script.sh so
#      $0 is useless; BUILD_SCRIPT_PATH holds the original repo-relative path
#      and CURRENT_DIR holds the runner's absolute working directory.
if [ -n "${BUILD_SCRIPT_PATH:-}" ] && [ -n "${CURRENT_DIR:-}" ]; then
    APP_PY="$(cd "$CURRENT_DIR" && cd "$(dirname "$BUILD_SCRIPT_PATH")" && pwd)/app.py"
else
    APP_PY="${SOURCE_ROOT}/app.py"
fi

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
echo -e "\n[tool.uv]\nenvironments = [\"python_version == '3.11' or python_version == '3.12' or python_version == '3.13' or python_version == '3.14'\"]" >> pyproject.toml

# Pin uv to the same Python that is active on this system
uv python pin ${PY_MAJOR_MINOR}

sed -i "s/.version=.*/version='"$PACKAGE_VERSION"',/" third-party/faiss/faiss/python/setup.py
export INDEX_URL_DEVPY="https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple"
sed -i '/^\[project\]/,/^$/ {s/version = "[^"]*"/version = "'"$PACKAGE_VERSION"'"/}' pyproject.toml

uv build --wheel --config-setting wheel.py-api=cp$CP --extra-index-url $INDEX_URL_DEVPY

WHEEL=$(find dist -maxdepth 1 -type f -name 'faiss_cpu-*.whl' | head -1)

if [ -z "$WHEEL" ]; then
    echo "------------------$PACKAGE_NAME:Failed to build wheel (no wheel found in dist/)-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Copy wheel to CURRENT_DIR so create_wheel_wrapper.sh can find it
cp "$WHEEL" "${CURRENT_DIR:-$(pwd)}/"

echo "Installing wheel: $WHEEL"

if ! (python3 -m pip install "$WHEEL" ); then
   echo "------------------$PACKAGE_NAME:Failed to build wheel-------------------------------------"
   echo "$PACKAGE_URL $PACKAGE_NAME"
   echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
fi

# Run tests
python3 -m pip install scipy==1.17.0 sentence-transformers --extra-index-url $INDEX_URL_DEVPY

TEST_PATH="$APP_PY"
if [ ! -f "${TEST_PATH}" ]; then
    echo "ERROR: test case not found at ${TEST_PATH}"
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