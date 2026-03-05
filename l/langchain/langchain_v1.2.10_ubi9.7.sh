#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : langchain
# Version          : 1.2.10
# Source repo      : https://github.com/langchain-ai/langchain
# Tested on        : UBI:9.7
# Language         : Python
# Ci-Check     	   : True
# Script License   : MIT License
# Maintainer       : Amit Kumar <amit.kumar282@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=langchain
PACKAGE_VERSION=${1:-langchain==1.2.10}
PACKAGE_URL=https://github.com/langchain-ai/langchain
CURRENT_DIR=${PWD}

export PIP_ROOT_USER_ACTION=ignore

echo "================ Installing system dependencies ================"

yum install -y \
    git make cmake zip tar wget \
    python3.12 python3.12-devel python3.12-pip \
    gcc-toolset-13 gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc \
    zlib-devel libjpeg-devel openssl openssl-devel \
    freetype-devel pkgconfig rust cargo diffutils \
    libyaml-devel ca-certificates

update-ca-trust
source /opt/rh/gcc-toolset-13/enable

python3.12 -m pip install --upgrade pip setuptools wheel build

echo "================ Cloning repository ================"
cd "${CURRENT_DIR}"
rm -rf "${PACKAGE_NAME}"

git clone --depth 1 --branch "${PACKAGE_VERSION}" "${PACKAGE_URL}"
cd "${PACKAGE_NAME}"

echo "================ Building wheel ================"
cd libs/langchain_v1
python3.12 -m build --wheel

WHEEL_FILE=$(ls dist/langchain-*.whl | head -n 1)

if [ ! -f "${WHEEL_FILE}" ]; then
    echo "Wheel build failed!"
    exit 1
fi

echo "Wheel created: ${WHEEL_FILE}"

echo "================ Installing built wheel ================"
python3.12 -m pip install "${WHEEL_FILE}"

echo "================ Installing test dependencies ================"
python3.12 -m pip install \
    pytest \
    syrupy \
    python-dotenv \
    blockbuster \
    pytest-asyncio \
    pytest-mock \
    pytest-timeout \
    toml

echo "================ Installing langchain test dependencies ================"

cd "${CURRENT_DIR}/${PACKAGE_NAME}/libs/standard-tests"
python3.12 -m pip install .

# Verify installation
python3.12 -c "import langchain_tests" || {
    echo "langchain_tests installation failed!"
    exit 1
}

echo "================ Running unit tests ================"

cd "${CURRENT_DIR}/${PACKAGE_NAME}/libs/langchain_v1"

if ! python3.12 -m pytest tests \
        -k "not integration and not test_socket_disabled" \
        -v ; then
    echo "------------------${PACKAGE_NAME}:test_fails---------------------"
    exit 2
fi

echo "------------------${PACKAGE_NAME}:install_&_unit_test_success---------------------"
echo "${PACKAGE_NAME} | ${PACKAGE_URL} | 1.2.10 | GitHub | Pass | Wheel_Built_&_Unit_Tests_Passed"

exit 0
