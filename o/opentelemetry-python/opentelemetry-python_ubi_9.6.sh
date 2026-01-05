#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : opentelemetry-python
# Version          : v1.37.0
# Source repo      : https://github.com/open-telemetry/opentelemetry-python
# Tested on        : UBI:9.6
# Language         : Python
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Ramnath Nayak <Ramnath.Nayak@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=opentelemetry-python
PACKAGE_VERSION=${1:-v1.37.0}
PACKAGE_URL=https://github.com/open-telemetry/opentelemetry-python
PACKAGE_DIR=opentelemetry-python

CURRENT_DIR=${PWD}

yum install -y git make cmake zip tar wget python3.12 python3.12-devel python3.12-pip python3-pip gcc-toolset-13 gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc zlib-devel libjpeg-devel openssl openssl-devel freetype-devel pkgconfig rust cargo diffutils libyaml-devel

source /opt/rh/gcc-toolset-13/enable

python3.12 -m pip install build tox
python3.12 -m pip install --prefer-binary grpcio --extra-index-url=https://wheels.developerfirst.ibm.com/ppc64le/linux

cd $CURRENT_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

echo -e "\n[tool.setuptools]\npackages = []" >> pyproject.toml
clean_version="${PACKAGE_VERSION#v}"
sed -i "s/^version = \".*\"/version = \"$clean_version\"/" pyproject.toml


#Build package
if ! ./scripts/build.sh ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#Tests
if !  tox -e opentelemetry-api && tox -e opentelemetry-sdk ; then
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


