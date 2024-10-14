#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : cytoolz
# Version          : 0.10.1
# Source repo      : https://github.com/pytoolz/cytoolz.git
# Tested on        : UBI:9.3
# Language         : Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Aastha Sharma <aastha.sharma4@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

# Variables
PACKAGE_NAME=cytoolz
PACKAGE_VERSION=${1:-0.10.1}
PACKAGE_URL=https://github.com/pytoolz/cytoolz.git

# Install necessary system dependencies
yum install -y git gcc gcc-c++ make wget openssl-devel bzip2-devel libffi-devel zlib-devel python-devel python-pip

#install package
wget https://files.pythonhosted.org/packages/62/b1/7f16703fe4a497879b1b457adf1e472fad2d4f030477698b16d2febf38bb/cytoolz-0.10.1.tar.gz#sha256=82f5bba81d73a5a6b06f2a3553ff9003d865952fcb32e1df192378dd944d8a5c
tar -xvzf cytoolz-0.10.1.tar.gz
cd $PACKAGE_NAME-$PACKAGE_VERSION

# Install additional dependencies
pip install .
pip install pytest wheel build Cython==0.29.21

#install
if ! python3 -m setup build ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi
