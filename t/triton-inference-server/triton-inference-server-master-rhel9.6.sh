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
PACKAGE_VERSION=${1:-v2.59.0}
PACKAGE_URL=https://github.com/triton-inference-server/server

yum install git python3.12-devel python3.12-pip cmake -y

ln /usr/bin/pip3.12 /usr/bin/pip3 -f && ln /usr/bin/python3.12 /usr/bin/python3 -f &&  ln /usr/bin/pip3.12 /usr/bin/pip -f

python3.12 -m pip install distro requests

git clone $PACKAGE_URL -b $PACKAGE_VERSION
cd $PACKAGE_NAME
git submodule update --init --recursive
cp $wdir/onnxruntime_backend.patch .       
git apply $wdir/triton_disable_test.patch  
git apply $wdir/rhelppc.patch

if ! ./build.py --enable-logging --endpoint http --backend onnxruntime --backend python --image base,registry.access.redhat.com/ubi9/ubi:9.6 ; then
    echo "------------------$PACKAGE_NAME:Build_fails---------------------"
    exit 2
    cd .. && rm -rf $PACKAGE_NAME
else
    echo "------------------$PACKAGE_NAME:Build_success-------------------"
    exit 0
fi

# Notes about patches:
# onnxruntime_backend.patch: We are patching https://github.com/triton-inference-server/onnxruntime_backend/blob/main/tools/gen_ort_dockerfile.py, these changes are required to build onnxruntime_backend on RHEL.To remove this patch we will have to upstream changes.
# triton_disable_test.patch: Patch to disable 1 test, issue is also observed on x86 as mentioned by third party user in https://github.com/triton-inference-server/server/issues/8202, can be removed once this issue is fixed.
# rhelppc.patch: This patch is required to build triton server image on RHEL.We will have to upstream changes to remove this patch.
