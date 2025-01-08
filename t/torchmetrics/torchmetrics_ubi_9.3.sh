#!/bin/bash -e
# ----------------------------------------------------------------------------
# 
# Package       : torchmetrics
# Version       : v1.4.0
# Source repo   : https://github.com/Lightning-AI/torchmetrics.git
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Haritha Nagothu <haritha.nagothu2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#variables
PACKAGE_NAME=torchmetrics
PACKAGE_VERSION=${1:- v1.4.0}
PACKAGE_URL=https://github.com/Lightning-AI/torchmetrics.git

# Install dependencies and tools.
yum install -y gcc gcc-c++ gcc-gfortran git make  python-devel  openssl-devel cmake zlib-devel libjpeg-devel wget


#clone repository 
git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#installing pytorch

wget https://repo.anaconda.com/miniconda/Miniconda3-py39_4.9.2-Linux-ppc64le.sh -O miniconda.sh
bash miniconda.sh -b -u -p $HOME/miniconda
export PATH="$HOME/miniconda/bin:$PATH"
conda install pytorch -y


#install
if ! (python3 setup.py install) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi
