#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : treepoem
# Version       : 3.24.0
# Source repo   : https://github.com/adamchainz/treepoem
# Tested on     : UBI: 9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Stuti Wali <Stuti.Wali@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -ex

#variables
PACKAGE_NAME="treepoem"
PACKAGE_VERSION=${1:-"3.24.0"}
PACKAGE_URL=https://github.com/adamchainz/treepoem
HOME_DIR=`pwd`

export PATH=${PATH}:$HOME/conda/bin
export LANG=en_US.utf8

# Install dependencies
yum install -y gcc gcc-c++ make autoconf automake git wget libjpeg-turbo-devel libpng-devel tar gzip libffi-devel openssl-devel python3 python3-devel


#installing ghostscript
wget https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs10031/ghostscript-10.03.1.tar.gz
tar -zxvf ghostscript-10.03.1.tar.gz
cd ghostscript-10.03.1
rm -rf libpng 
sh autogen.sh
./configure
make
make install
cd ..


# Clone the repository
cd $HOME_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
pip install --upgrade requests
pip install --upgrade tox pytest
export TOXENV=py39

# Build package
if !(pip install -r requirements/py39.txt) ; then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

# Run test cases
# Skipping "test_barcode", reference : https://github.com/adamchainz/treepoem/issues/554
if !(tox -e py39 -- -k "not test_barcode"); then
    echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:build_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi

