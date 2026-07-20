#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package           : faiss
# Version           : 1.9.0-post1
# Source repo       : https://github.com/faiss-wheels/faiss-wheels
# Tested on         : UBI 9.6
# Language          : C++, Python
# Ci-Check      : True
# Script License    : Apache License Version 2.0
# Maintainer        : Amir Sanjar <amir.sanjar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such cases, please
#             contact the "Maintainer" of this script.
#

# set -e

PACKAGE_NAME=faiss-cpu
PACKAGE_DIR=faiss-wheels
PACKAGE_VERSION=${1:-1.9.0.post1}
PACKAGE_URL=https://github.com/faiss-wheels/faiss-wheels.git
SOURCE_ROOT="$(pwd)"



echo "Installing dependencies..."
curl -O https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
dnf install -y epel-release-latest-9.noarch.rpm
dnf update -y 
dnf install -y  \
     python3.13 python3.13-devel python3.13-pip \
     openblas-devel make gcc g++ cmake git automake autoconf

echo "Upgrading Python tools..."
python3.13 -m pip install --upgrade setuptools wheel build  uv

git clone --recursive ${PACKAGE_URL}
cd ${PACKAGE_DIR}
echo -e "\n[tool.uv]\nenvironments = [\"python_version == '3.13'\"]" >> pyproject.toml
uv python pin 3.13
sed -i "s/.version=.*/version='"$PACKAGE_VERSION"',/" third-party/faiss/faiss/python/setup.py
export INDEX_URL_DEVPY="https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple"
sed -i '/^\[project\]/,/^$/ {s/version = "[^"]*"/version = "'"$PACKAGE_VERSION"'"/}' pyproject.toml
CP=$(python3.13 -c "import sysconfig; print(sysconfig.get_config_var('py_version_nodot'))")
uv build --wheel --config-setting wheel.py-api=cp$CP --extra-index-url $INDEX_URL_DEVPY

if ! (python3.13 -m pip install dist/faiss_cpu-$PACKAGE_VERSION-cp$CP-abi3-linux_ppc64le.whl ); then 
   echo "------------------$PACKAGE_NAME:Failed to build wheel-------------------------------------"
   echo "$PACKAGE_URL $PACKAGE_NAME"
   echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
fi
# Run tests
python3.13 -m pip install  scipy==1.17.0 sentence-transformers  --extra-index-url $INDEX_URL_DEVPY 
#find test case called app.py
TEST_PATH=$(find "${SOURCE_ROOT}" -name app.py | head -1)
if [ -z "${PATCH_PATH}" ]; then
    echo "ERROR: test case not found"
    exit 1
fi
if ! (python3.13 $TEST_PATH); then
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
