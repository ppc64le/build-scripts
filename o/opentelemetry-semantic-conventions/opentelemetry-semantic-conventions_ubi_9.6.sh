#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : opentelemetry-semantic-conventions
# Version          : v1.44.0
# Source repo      : https://github.com/open-telemetry/opentelemetry-python.git
# Tested on        : UBI:9.6
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Bhagyashri Gaikwad <Bhagyashri.Gaikwad2@ibm.com> 
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash
set -ex

# Variables
PACKAGE_NAME="opentelemetry-semantic-conventions"
PACKAGE_VERSION="${1:-v1.44.0}"
PACKAGE_URL="https://github.com/open-telemetry/opentelemetry-python.git"
REPO_DIR="opentelemetry-python"
CURRENT_DIR="${PWD}"

# Install system dependencies
yum install -y git gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ \
    make wget python3.12 python3.12-devel python3.12-pip

# Verify Python and pip
python3.12 --version
python3.12 -m pip --version

# Clone repository
git clone "${PACKAGE_URL}" "${CURRENT_DIR}/${REPO_DIR}"
cd "${CURRENT_DIR}/${REPO_DIR}"

# Checkout requested version
git checkout "${PACKAGE_VERSION}"

# Navigate to the actual package directory
PACKAGE_DIR="${PWD}/${PACKAGE_NAME}"

if [ ! -f "${PACKAGE_DIR}/pyproject.toml" ]; then
    echo "ERROR: pyproject.toml not found in ${PACKAGE_DIR}"
    find . -maxdepth 2 -name pyproject.toml -print
    exit 1
fi

cd "${PACKAGE_DIR}"
echo "Building package from: ${PWD}"

# Install Python build and test dependencies
python3.12 -m pip install --upgrade pip setuptools wheel
python3.12 -m pip install hatchling editables packaging pytest build

# Verify build backend
python3.12 -c "import hatchling.build; print('Hatchling build backend is available')"
python3.12 -c "from editables import EditableProject; print('Editables dependency is available')"

# Build wheel from the package directory
if ! python3.12 -m build --wheel --no-isolation \
    --outdir="${CURRENT_DIR}"; then
    echo "------------------${PACKAGE_NAME}:Wheel_Build_Fails------------------"
    echo "${PACKAGE_NAME} | ${PACKAGE_VERSION} | GitHub | Fail | Wheel_Build_Fails"
    exit 1
fi

# Install package
if ! python3.12 -m pip install --no-build-isolation -e "${PACKAGE_DIR}"; then
    echo "------------------${PACKAGE_NAME}:Install_Fails---------------------"
    echo "${PACKAGE_NAME} | ${PACKAGE_VERSION} | GitHub | Fail | Install_Fails"
    exit 1
fi

# Verify installation
python3.12 -m pip show "${PACKAGE_NAME}"

# Verify package import
if ! python3.12 -c \
    "import opentelemetry.semconv; print('Package import successful')"; then
    echo "------------------${PACKAGE_NAME}:Import_Fails----------------------"
    echo "${PACKAGE_NAME} | ${PACKAGE_VERSION} | GitHub | Fail | Import_Fails"
    exit 2
fi

# Run tests from the package directory
if [ -d tests ]; then
    TEST_PATH="tests"
elif [ -d test ]; then
    TEST_PATH="test"
else
    TEST_PATH=""
fi

if [ -n "${TEST_PATH}" ]; then
    if ! python3.12 -m pytest -v --capture=no -p no:warnings "${TEST_PATH}"; then
        echo "------------------${PACKAGE_NAME}:Tests_Fail------------------------"
        echo "${PACKAGE_NAME} | ${PACKAGE_VERSION} | GitHub | Fail | Test_Fails"
        exit 2
    fi
else
    echo "No package-specific tests directory found; skipping pytest."
fi

# Report status
echo "------------------${PACKAGE_NAME}:Build_Install_Test_Success---------"
echo "${PACKAGE_URL} ${PACKAGE_NAME}"
echo "${PACKAGE_NAME} | ${PACKAGE_VERSION} | GitHub | Pass | Build_Install_Test_Success"
