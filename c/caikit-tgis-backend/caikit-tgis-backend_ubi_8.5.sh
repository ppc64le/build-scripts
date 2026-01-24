#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package       : caikit-tgis-backend
# Source repo   : https://github.com/caikit/caikit-tgis-backend
# Version       : v0.1.14
# Tested on     : UBI:8.5
# Language      : python
# Travis-Check  : True
# Script License: Apache License 2.0
# Maintainer    : Viren Dalgade <Viren.Dalgade@ibm.com>
#
# Disclaimer: This script has been tested with non-root user on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
set -e
echo "creating creating caikit-tgis-backend-user(non root user) user and swithching to creating caikit-tgis-backend-user "
export USER_NAME=caikit-tgis-backend-user
export USERDIR=/home/caikit-tgis-backend-user
useradd --create-home --home-dir $USERDIR --shell /bin/bash $USER_NAME
usermod -aG wheel $USER_NAME
yum install -y sudo
su $USER_NAME
cd $USERDIR
echo " Current directory: $PWD "

#Installation of all dependancies 
PACKAGE_NAME="caikit-tgis-backend"
PACKAGE_URL="https://github.com/caikit/caikit-tgis-backend"
PACKAGE_TAG=${1:-v0.1.14}
PACKAGE_BRANCH=main
yum install -y git wget
yum install -y python39
pip3.9 install --upgrade pip
yum install -y gcc-c++
yum install -y python39-devel libffi-devel
yum install -y redhat-rpm-config openssl-devel cargo pkg-config
pip3.9 install setuptools==49.6.0
pip3.9 install wheel && GRPC_BUILD_WITH_BORING_SSL_ASM="" GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=true GRPC_PYTHON_BUILD_SYSTEM_ZLIB=true pip3.9 install grpcio

#cloning the git repo of caikit-tgis-backend
#Check if package exists
if [ -d "$PACKAGE_NAME" ] ; then
  rm -rf $PACKAGE_NAME
  echo "$PACKAGE_NAME  | $PACKAGE_TAG | GitHub | Removed existing package if any"
fi

if ! git clone $PACKAGE_URL -b $PACKAGE_BRANCH ; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_TAG | GitHub  | Fail |"
    exit 1
fi

echo "BRANCH_NAME = $PACKAGE_BRANCH"
git config --global --add safe.directory $USERDIR/$PACKAGE_NAME
chown -R $USER_NAME:$USER_NAME $USERDIR
cd $PACKAGE_NAME

#checkout to latest tag
if ! git checkout $PACKAGE_TAG ; then
    echo "------------------$PACKAGE_TAG:invalid tag---------------------------------------"
    exit 1
else 
    echo "------------------$PACKAGE_TAG:valid tag---------------------------------------"
fi

#Installation of pre-requisite from repo caikit-tgis-backend
pip3.9 install tox==4.6.4
pip3.9 install build==0.10.0
pip3.9 install .
export PATH=$PATH:/usr/local/bin

#Unit tests
if ! ( tox -e 3.9 ); then
        echo "------------------$PACKAGE_NAME:test_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_TAG | $OS_NAME | GitHub | Fail |  test_fails"
        exit 1
else
        echo "------------------$PACKAGE_NAME:test_success-------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_TAG | $OS_NAME | GitHub  | Pass |  test_success"
fi


