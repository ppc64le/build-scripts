#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: scipy
# Version	: v1.6.3
# Source repo	: https://github.com/scipy/scipy
# Tested on	: UBI 8.5
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Anup Kodlekere <Anup.Kodlekere@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=scipy
PACKAGE_VERSION=${1:-v1.6.3}
PACKAGE_URL=https://github.com/scipy/scipy

OS_NAME=`cat /etc/os-release | grep "PRETTY" | awk -F '=' '{print $2}'`

SCRIPT=$(readlink -f $0)
SCRIPT_DIR=$(dirname $SCRIPT)

STATS_PATCH=$SCRIPT_DIR/stats.patch
TEST_STATS_PATCH=$SCRIPT_DIR/test_stats.patch
TEST_SHORTEST_PATH_PATCH=$SCRIPT_DIR/test_shortest_path.patch

# install core dependencies
yum install -y gcc gcc-c++ gcc-gfortran python39 python39-devel git make openblas atlas diffutils patch

# change symbolic links so that python can find them
ln -s /usr/lib64/atlas/libtatlas.so.3 /usr/lib64/atlas/libtatlas.so
ln -s /usr/lib64/libopenblas.so.0 /usr/lib64/libopenblas.so

# install scipy dependencies
python3.9 -m pip install cython numpy pybind11 pytest pythran

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#patch files here
patch -u scipy/stats/stats.py -i $STATS_PATCH
patch -u scipy/stats/tests/test_stats.py -i $TEST_STATS_PATCH
patch -u scipy/sparse/csgraph/tests/test_shortest_path.py -i $TEST_SHORTEST_PATH_PATCH
sed -i '2526s/skip/skipif/' scipy/linalg/tests/test_decomp.py

if ! python3.9 runtests.py --build-only; then
	echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
	exit 1
fi

if ! python3.9 runtests.py; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_and_test_success-------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Install_and_Test_Success"
	exit 0
fi