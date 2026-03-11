#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : spacy
# Version          : v3.8.7
# Source repo      : https://github.com/explosion/spaCy
# Tested on        : UBI:9.6
# Language         : Python, MDX
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Puneet Sharma <Puneet.Sharma21@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


PACKAGE_NAME=spacy
PACKAGE_URL=https://github.com/explosion/spaCy
PACKAGE_VERSION=${1:-release-v3.8.7}
PACKAGE_DIR=spaCy


dnf -y install git python3 python3-pip python3-devel make gcc-toolset-13 openblas-devel

# Enable GCC toolset
source /opt/rh/gcc-toolset-13/enable
export CC=/opt/rh/gcc-toolset-13/root/usr/bin/gcc
export CXX=/opt/rh/gcc-toolset-13/root/usr/bin/g++

# Clone repository
git clone ${PACKAGE_URL}
cd ${PACKAGE_DIR}
git checkout ${PACKAGE_VERSION}

# Upgrade build tools
python3 -m pip install --upgrade pip setuptools wheel

# Install build dependencies
python3 -m pip install --no-cache-dir cython numpy pytest setuptools

echo "building spacy..."

if ! python3 -m pip install --no-cache-dir .; then
    echo "------------------$PACKAGE_NAME: build_fail------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Build_Fail"
    exit 1
else
    echo "------------------$PACKAGE_NAME:build_success-----------------"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Build_Success"
fi

cd /

# functional test
if ! (python3 - <<EOF
import spacy
from spacy.tokens import Doc
from spacy.vocab import Vocab

print("spaCy version:", spacy.__version__)

nlp = spacy.blank("en")
doc = nlp("Testing spaCy on POWER architecture")

print("Tokens:", [t.text for t in doc])
print("spaCy build test passed")
EOF
); then
    echo "--------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Both_Install_and_Test_Success"
    exit 0
fi
