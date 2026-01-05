#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : langchain
# Version          : 0.3.27
# Source repo      : https://github.com/langchain-ai/langchain
# Tested on        : UBI:9.6
# Language         : Python
# Ci-Check     : True
# Script License   : MIT License
# Maintainer       : Ramnath Nayak <Ramnath.Nayak@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=langchain
PACKAGE_VERSION=${1:-langchain==0.3.27}
PACKAGE_URL=https://github.com/langchain-ai/langchain
PACKAGE_DIR=langchain/libs/langchain

CURRENT_DIR=${PWD}

yum install -y git make cmake zip tar wget python3.12 python3.12-devel python3.12-pip gcc-toolset-13 gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc zlib-devel libjpeg-devel openssl openssl-devel freetype-devel pkgconfig rust cargo diffutils libyaml-devel

source /opt/rh/gcc-toolset-13/enable

python3.12 -m pip install uv

cd $CURRENT_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

cd libs/langchain
PY_VERSION=$(python3.12 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
export UV_PYTHON="python${PY_VERSION}"


# Commenting out playwright and duckdb-engine because they are not supported on Power architecture.
# Playwright provides binaries only for x86 architectures and lacks Power support.
# DuckDB uses the 'pause' CPU instruction available only on x86, causing build failures on Power.
sed -i -e '/{ name = "playwright"/s/^/#/g' -e '/{ name = "duckdb-engine"/s/^/#/g' uv.lock


#Build package
if ! python3.12 -m pip install . ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#Tests
if ! make tests ; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
