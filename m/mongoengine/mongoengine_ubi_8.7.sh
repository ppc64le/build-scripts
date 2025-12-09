#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : mongoengine
# Version       : v0.27.0
# Source repo   : https://github.com/MongoEngine/mongoengine
# Tested on     : UBI 8.7
# Language      : Java
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Abhishek Dwivedi <Abhishek.Dwivedi6@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME=mongoengine
PACKAGE_VERSION=${1:-v0.27.0}
PACKAGE_URL=https://github.com/MongoEngine/mongoengine

HOME_DIR=`pwd`

yum update -y
yum install -y yum-utils

yum install -y python38 python38-pip git zlib-devel libjpeg-turbo libjpeg-turbo-devel gcc gcc-c++ python38-devel libtiff freetype freetype-devel libwebp openjpeg2 wget
yum install python3-pymongo.ppc64le -y

wget https://repo.anaconda.com/miniconda/Miniconda3-py39_4.9.2-Linux-ppc64le.sh -O miniconda.sh 
bash miniconda.sh -b -p $HOME/miniconda 
export PATH="$HOME/miniconda/bin:$PATH"
python3 -m pip install -U pip
python3 -m pip install tox
conda install -y conda-forge::mongodb

git clone $PACKAGE_URL $PACKAGE_NAME
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION 

python3 -m pip install -r docs/requirements.txt

if ! python3 -m pip install -e . ;  then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi
if ! tox -e $(echo py3.9-mg311 | tr -d . | sed -e 's/pypypy/pypy/') -- -a "-k=test_ci_placeholder" ; then
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