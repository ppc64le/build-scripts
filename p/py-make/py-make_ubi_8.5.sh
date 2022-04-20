#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: py-make
# Version	: v0.1.1
# Source repo	: https://github.com/tqdm/py-make
# Tested on	: UBI 8.5
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Anup Kodlekere / Vedang Wartikar <Vedang.Wartikar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=py-make
PACKAGE_VERSION=${1:-v0.1.1}
PACKAGE_URL=https://github.com/tqdm/py-make

yum install -y python36 make git

mkdir -p /home/tester && cd /home/tester

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

export TOXENV=py36

pip3 install tox
pip3 install .

tox
ret=$?
if [ $ret -ne 0 ] ; then
  echo "Build & Test failed for python 3.6 environment"
else
  echo "Build & Test Success for python 3.6 environment"
fi