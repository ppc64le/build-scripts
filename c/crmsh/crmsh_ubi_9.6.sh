#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : crmsh
# Version          : 4.6.0
# Source repo      : https://github.com/ClusterLabs/crmsh.git
# Tested on        : UBI:9.6
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vipul Ajmera <Vipul.Ajmera@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

#variables
PACKAGE_NAME=crmsh
PACKAGE_VERSION=${1:-4.6.0}
PACKAGE_URL=https://github.com/ClusterLabs/crmsh.git
PACKAGE_DIR=crmsh

#install dependencies
yum install -y wget git python3 python3-pip python3-devel libxml2-devel libxslt-devel gcc-toolset-13-gcc
source /opt/rh/gcc-toolset-13/enable

git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

python3 -m pip install --upgrade pip build wheel
python3 -m pip install --upgrade --ignore-installed chardet tox
python3 -m pip install -r requirements.txt

# Generate the actual version file from version.in so setup.py picks up the correct PACKAGE_VERSION
sed "s/@PACKAGE_VERSION@/$PACKAGE_VERSION/" version.in > version

if ! python3 -m pip install . --no-build-isolation ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Run tests (Unit tests/tests are intentionally skipped for Python 3.12 due to upstream incompatibilities caused by removal of distutils in the Python standard library.)
if ! (python3 -c "import crmsh"); then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
