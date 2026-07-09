#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pyjnius
# Version       : 1.6.1
# Source repo   : https://github.com/kivy/pyjnius.git
# Tested on     : registry.access.redhat.com/ubi9/ubi:9.6
# Language      : Python , Java ,Cython
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Prerna Kumbhar <Prerna.Kumbhar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
################################# Pyjnius ##################################

PACKAGE_NAME=pyjnius
PACKAGE_URL=https://github.com/kivy/pyjnius.git
PACKAGE_VERSION=${1:-1.6.1}
PYTHON_VERSION=${2:-3.12}
export wdir=`pwd`

yum install -y git wget python${PYTHON_VERSION}-devel python${PYTHON_VERSION}-pip cmake python${PYTHON_VERSION}-devel python${PYTHON_VERSION}-pip java-17-openjdk java-17-openjdk-devel  gcc gcc-c++ make 

ln /usr/bin/pip${PYTHON_VERSION} /usr/bin/pip3 -f && ln /usr/bin/python${PYTHON_VERSION} /usr/bin/python3 -f &&  ln /usr/bin/pip${PYTHON_VERSION} /usr/bin/pip -f && ln /usr/bin/python${PYTHON_VERSION} /usr/bin/python -f

pip3 install --upgrade pip  build setuptools wheel "Cython<3" pytest


#Clone Pyjnius repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/p/pyjnius/pyjnius.patch
git apply pyjnius.patch

if ! python3 -m pip wheel . --no-build-isolation; then 
     echo "------------------$PACKAGE_NAME:Build_fails-------------------------------------"
     echo "$PACKAGE_URL $PACKAGE_NAME"
     echo "$PACKAGE_NAME  |  $PACKAGE_URL  | $PACKAGE_VERSION | GitHub | Fail |  Build_fails"
     exit 2;
fi

mkdir -p tests/java-classes
javac -encoding UTF-8 -d tests/java-classes $(find tests/java-src -name "*.java")
export CLASSPATH=$wdir/pyjnius/tests/java-classes

# Install the built wheel
pip3 install pyjnius-*.whl
cd $wdir
if ! pytest -v pyjnius/tests; then
     echo "------------------$PACKAGE_NAME:Test_fails-------------------------------------"
     echo "$PACKAGE_URL $PACKAGE_NAME"
     echo "$PACKAGE_NAME  |  $PACKAGE_URL  | $PACKAGE_VERSION | GitHub | Fail |  Build_success_but_test_Fails"
     exit 1
else
     echo "------------------$PACKAGE_NAME:Build_and_test_both_success-------------------------------------"
     echo "$PACKAGE_URL $PACKAGE_NAME"
     echo "$PACKAGE_NAME  |  $PACKAGE_URL  | $PACKAGE_VERSION | GitHub | Pass |  Both_Build_and_Test_Success"
     exit 0
fi

