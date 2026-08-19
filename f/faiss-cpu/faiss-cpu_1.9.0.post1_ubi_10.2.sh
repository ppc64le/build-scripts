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
# Build notes:
#   faiss-wheels uses scikit-build-core as its build backend.  scikit-build-core
#   drives CMake internally — no separate cmake phase is required.
#   System pre-requisite: openblas-devel (mirrors scripts/install_Linux.sh).
#   Build-time deps (swig, numpy) are declared in pyproject.toml
#   build-system.requires and are installed automatically by pip.
#   The wheel is built as a stable-ABI (cp310-abi3) wheel, compatible with
#   Python 3.10 through 3.14.

set -e
PACKAGE_NAME=faiss-cpu
PACKAGE_DIR=faiss-wheels
PACKAGE_VERSION=${1:-1.9.0.post1}
PACKAGE_VERSION=${PACKAGE_VERSION#v}
PACKAGE_URL=https://github.com/faiss-wheels/faiss-wheels.git

# Resolve app.py to an absolute path before any cd into subdirectories.
# Two execution contexts:
#   1. validate_builds_currency.py (direct run): $0 is the real script path.
#   2. create_wheel_wrapper.sh: script is copied to temp_build_script.sh;
#      BUILD_SCRIPT_PATH holds the original path, CURRENT_DIR the working dir.
if [ -n "${BUILD_SCRIPT_PATH:-}" ] && [ -n "${CURRENT_DIR:-}" ]; then
    APP_PY="$(cd "$CURRENT_DIR" && cd "$(dirname "$BUILD_SCRIPT_PATH")" && pwd)/app.py"
else
    SOURCE_ROOT="$(cd "$(dirname "$0")" && pwd)"
    APP_PY="${SOURCE_ROOT}/app.py"
fi

echo "Installing dependencies..."
dnf update -y
# Only openblas-devel is needed as a system dep; swig and numpy are pulled in
# automatically by pip via pyproject.toml build-system.requires.
dnf install -y \
    python3 python3-devel python3-pip \
    openblas-devel \
    make gcc g++ cmake git

echo "Upgrading Python tools..."
python3 -m ensurepip --upgrade
python3 -m pip install --upgrade pip setuptools wheel build

export INDEX_URL_DEVPY="https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple"
export FAISS_OPT_LEVELS="generic"
export FAISS_GPU_SUPPORT="OFF"
export FAISS_ENABLE_MKL="OFF"

git clone --recursive ${PACKAGE_URL}
cd ${PACKAGE_DIR}

# Pin version in pyproject.toml so the built wheel carries PACKAGE_VERSION.
sed -i "s/^version = \"[^\"]*\"/version = \"${PACKAGE_VERSION}\"/" pyproject.toml

# Build the wheel using scikit-build-core (drives CMake + SWIG internally).
# --no-isolation: use the active Python environment (venv or system).
# Wheel lands in CURRENT_DIR (or pwd for the currency pipeline).
python3 -m build --wheel --no-isolation \
    --outdir "${CURRENT_DIR:-$(pwd)}"

WHEEL=$(ls "${CURRENT_DIR:-$(pwd)}"/faiss_cpu-${PACKAGE_VERSION}-*.whl 2>/dev/null | head -1)
if [ -z "$WHEEL" ]; then
    echo "------------------$PACKAGE_NAME:Install_Fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! python3 -m pip install "$WHEEL"; then
    echo "------------------$PACKAGE_NAME:Install_Fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Run tests
python3 -m pip install scipy==1.17.0 sentence-transformers --extra-index-url $INDEX_URL_DEVPY

if [ ! -f "${APP_PY}" ]; then
    echo "ERROR: test case not found at ${APP_PY}"
    exit 1
fi

if ! python3 "${APP_PY}"; then
    echo "--------------------$PACKAGE_NAME:Install_success_but_test_fails--------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Import_Success"
fi
