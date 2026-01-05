#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : kafka-python
# Version          : 2.2.10
# Source repo      : https://github.com/dpkp/kafka-python
# Tested on        : UBI 9.5
# Language         : Python
# Ci-Check     : True
# Script License   : GNU General Public License v3.0
# Maintainer       : Haritha Nagothu <haritha.nagothu2@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

PACKAGE_NAME=kafka-python
PACKAGE_VERSION=${1:-2.2.10}
PACKAGE_URL=https://github.com/dpkp/kafka-python
PACKAGE_DIR=kafka-python
SCRIPT_DIR=$(pwd)

yum install -y python3-devel python3-pip git gcc-toolset-13 cmake libzstd-devel
source /opt/rh/gcc-toolset-13/enable
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH

#Installing snappy
git clone --recurse-submodules https://github.com/google/snappy.git
cd snappy
git submodule update --init --recursive
mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local ..
make -j$(nproc)
make install
cd $SCRIPT_DIR
export SNAPPY_HOME=/usr/local
export CMAKE_PREFIX_PATH=$SNAPPY_HOME
export LD_LIBRARY_PATH=$SNAPPY_HOME/lib64:$LD_LIBRARY_PATH

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

pip install -r requirements-dev.txt
pip install pytest pytest-timeout

if ! pip install . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

cd test/

if ! pytest; then
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
