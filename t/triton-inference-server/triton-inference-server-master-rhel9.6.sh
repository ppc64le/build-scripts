#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package       : triton-inference-server
# Version       : master(41844940e1601f223c33f)
# Source repo   : https://github.com/triton-inference-server/server
# Tested on     : RHEL 9.6
# Language      : Python , Shell
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer    : Sunidhi Gaonkar<Sunidhi.Gaonkar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#We have set the travis check to false as this script is directly run on rhel VM. Needs docker.

wdir=`pwd`
PACKAGE_NAME=server
PACKAGE_URL=https://github.com/triton-inference-server/server

yum install git python3.12-devel python3.12-pip cmake -y

ln /usr/bin/pip3.12 /usr/bin/pip3 -f && ln /usr/bin/python3.12 /usr/bin/python3 -f &&  ln /usr/bin/pip3.12 /usr/bin/pip -f

pip install distro requests

git clone $PACKAGE_URL
cd $PACKAGE_NAME
 
git apply $wdir/triton_disable_test.patch
git apply $wdir/rhelppc.patch

if ! ./build.py --enable-logging --endpoint http --backend python --image base,registry.access.redhat.com/ubi9/ubi:9.6 ; then
    echo "------------------$PACKAGE_NAME:Build_fails---------------------"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Build_success-------------------"
    exit 0
fi
