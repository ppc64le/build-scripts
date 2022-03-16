#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: watchdog
# Version	: v2.0.3
# Source repo	: https://github.com/gorakhargosh/watchdog
# Tested on	: UBI: 8.5
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Sunidhi Gaonkar / Vedang Wartikar<Vedang.Wartikar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=watchdog
PACKAGE_VERSION=${1:-v2.0.3}
PACKAGE_URL=https://github.com/gorakhargosh/watchdog

yum install -y python36 python36-devel git python2 python2-devel python3 python3-devel ncurses git gcc gcc-c++ libffi libffi-devel sqlite sqlite-devel sqlite-libs python3-pytest make cmake

mkdir -p /home/tester
cd /home/tester

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

python3 -m pip install -e .
python3 -m pip install tox
python3 -m tox -e py



