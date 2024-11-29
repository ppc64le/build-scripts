#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : scikit-learn
# Version       : 1.5.0
# Source repo   : https://github.com/scikit-learn/scikit-learn.git
# Tested on     : UBI 8.10
# Language      : Python, Cython, C++
# Travis-Check  : False
# Script License: Apache License 2.0
# Maintainer    : Salil Verlekar <Salil.Verlekar2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=scikit-learn
PACKAGE_VERSION=${1:-1.5.0}
PACKAGE_URL=https://github.com/scikit-learn/scikit-learn.git

yum install -y python3.11 python3.11-pip python3.11-devel gcc gcc-c++ gcc-gfortran gcc-toolset-10 git
yum install -y openblas-devel --enablerepo=codeready-builder-for-rhel-8-ppc64le-rpms

source /opt/rh/gcc-toolset-10/enable

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

# clone source repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init

# install scikit-learn dependencies and build dependencies
python3.11 -m pip install wheel numpy scipy cython meson-python ninja 'pytest==8.2.2' 'patchelf>=0.11.0' build

export SKLEARN_SKIP_OPENMP_TEST=1

ln -s /usr/bin/python3.11 python
mv python /usr/bin

# build wheel in /scikit-learn/dist
if ! python3.11 -m build --wheel --no-isolation; then
        echo "------------------$PACKAGE_NAME:build_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
        exit 1
else
        echo "------------------$PACKAGE_NAME:build_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Build_Success"
fi

# install wheel, run show and check that the installed scikit-learn has a version number
python3.11 -m pip install dist/scikit_learn-1.5.0-cp311-cp311-linux_ppc64le.whl
python3.11 -m pip show scikit-learn
cd sklearn
python3.11 -c "import sklearn; sklearn.show_versions()"

if [ $? == 0 ]; then
     echo "------------------$PACKAGE_NAME::Install_Success---------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Pass |  Install_Success"
else
     echo "------------------$PACKAGE_NAME::Install_Fail-------------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Fail |  Install_Fail"
     exit 2
fi

# test using pytest - set below flag as suggested in GitHub forums to resolve ImportPathMismatchError
export PY_IGNORE_IMPORTMISMATCH=1
if ! pytest tests/test_random_projection.py ; then
        echo "------------------$PACKAGE_NAME:test_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME "
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | Github | Fail |  Test_Fails"
        exit 2
else
        echo "------------------$PACKAGE_NAME:test_success-------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME "
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | Github | Pass |  Test_Success"
	exit 0
fi
