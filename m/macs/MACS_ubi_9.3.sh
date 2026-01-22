#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : MACS
# Version          : v3.0.1
# Source repo      : https://github.com/macs3-project/MACS/
# Tested on        : UBI: 9.3
# Language         : Cython, Python
# Ci-Check     : True
# Script License   : GNU General Public License v3.0
# Maintainer       : Aastha Sharma <aastha.sharma4@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
set -ex

PACKAGE_NAME=MACS
PACKAGE_VERSION=${1:-v3.0.1}
PACKAGE_URL=https://github.com/macs3-project/MACS/
PACKAGE_DIR=MACS
wrkdir=`pwd`

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

yum install -y wget git gcc-toolset-13 cmake procps-ng diffutils bc python3 python3-devel python3-pip openblas-devel zlib-devel

#export path for gcc-13
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init --recursive

#install dependencies
pip install scipy meson-python pybind11 pythran cython wheel ninja
pip install --upgrade --progress-bar off pytest
pip install "hmmlearn>=0.3.2"

if ! python3 -m pip install --upgrade-strategy only-if-needed --no-build-isolation . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! pytest --runxfail && cd test && ./cmdlinetest macs3 ; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
