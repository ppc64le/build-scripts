#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : Rshiny-server
# Version       : v1.5.20.1002
# Source repo   : https://github.com/rstudio/shiny-server.git
# Tested on     : UBI 8.7
# Language      : Javascript
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Ujwal Akare <Ujwal.Akare@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
# Create a user and give all the permission to user in 'visudo'
# useradd test
# passwd test
# add "test     ALL=(ALL)       ALL" in visudo file.
# su test
# cd
USER_NAME=test
USERDIR=/home/test
PACKAGE_NAME=Rshiny-server
PACKAGE_TAG=${1:-v1.5.20.1002}
PACKAGE_BRANCH=master
PACKAGE_URL=https://github.com/rstudio/shiny-server.git

#Download Updates and Dependencies
dnf update -y

#install required prerequisites
dnf install -y gcc gcc-c++ git wget xz cmake make python3.8 openssl-devel

#Install R from Source

# Required repo to pickup additional EPEL package
dnf install --nodocs -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
dnf update -y
#Install required dependencies
dnf builddep R -y
export R_VERSION=4.2.3
# Download and extract R
curl -O https://cran.rstudio.com/src/base/R-4/R-${R_VERSION}.tar.gz
tar -xzvf R-${R_VERSION}.tar.gz
cd R-${R_VERSION}
#Build and install R
./configure --prefix=/opt/R/${R_VERSION} --enable-R-shlib --enable-memory-profiling
make
make install
export PATH=$PATH:/opt/R/4.2.3/bin
R --version

#Check if package exists
if [ -d "$PACKAGE_NAME" ] ; then
  rm -rf $PACKAGE_NAME
  echo "$PACKAGE_NAME  | $PACKAGE_TAG | GitHub | Removed existing package if any"
fi

if ! git clone $PACKAGE_URL -b $PACKAGE_BRANCH ; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_TAG | GitHub  | Pass |"
    exit 0
fi

echo "BRANCH_NAME = $PACKAGE_BRANCH"
chown -R $USER_NAME:$USER_NAME $USERDIR
cd $PACKAGE_NAME

#checkout to latest version
git checkout $PACKAGE_TAG 

mkdir tmp

cd tmp

#update line 8 of the install-node.sh file by replacing its content with the specified NODE_SHA256 value.
sed -i '8s/.*/NODE_SHA256=25aa3bb52ee6ca29b93dec388c2b5d66265315ffae18be9a8fc2391f656bbe4f/' ../external/node/install-node.sh

#searche for the string "linux-x64.tar.xz" in the install-node.sh file and replace it with "linux-ppc64le.tar.xz"
sed -i 's/linux-x64.tar.xz/linux-ppc64le.tar.xz/'  ../external/node/install-node.sh

../external/node/install-node.sh
DIR=`pwd`
PATH=$DIR/../bin:$PATH
export PYTHON=`which python3.8`
export PATH=$PYTHON:$PATH

#configure the build system using cmake.
cmake -DCMAKE_INSTALL_PREFIX=/usr/local -DPYTHON="$PYTHON" ../

make
mkdir ../build

#change the current working directory to the parent directory and then execute the npm install.
(cd .. && ./bin/npm install)

#install the built files
if !    make install; then
        echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_TAG | $OS_NAME | GitHub | Fail |  Install_Fails"
        exit 1
fi

#Configuration for R-shiny server
mkdir -p /etc/shiny-server
cp ../config/default.config /etc/shiny-server/shiny-server.conf

if ! ( npm install &&  npm test); then
        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_TAG | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
        exit 1
else
        echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_TAG | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
        exit 0
fi

