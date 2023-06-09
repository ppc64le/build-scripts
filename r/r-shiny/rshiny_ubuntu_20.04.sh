#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : r-shiny
# Version       : v1.5.20.1002
# Source repo   : https://github.com/rstudio/shiny-server.git
# Tested on     : ubuntu_20.04
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
# add "test    ALL=(ALL:ALL) ALL" in visudo file.
# su test
# cd
USER_NAME=test
USERDIR=/home/test
PACKAGE_NAME=shiny-server
PACKAGE_TAG=${1:-v1.5.20.1002}
PACKAGE_BRANCH=master
PACKAGE_URL=https://github.com/rstudio/shiny-server.git

#Download Updates and Dependencies
#apt-get update -y

#install required prerequisites
apt install -y gcc g++ git wget cmake make python3.8 r-base libssl-dev

#Check if package exists
if [ -d "$PACKAGE_NAME" ] ; then
  rm -rf $PACKAGE_NAME
  echo "$PACKAGE_NAME  | $PACKAGE_TAG | $OS_NAME | GitHub | Removed existing package if any"
fi

if ! git clone $PACKAGE_URL -b $PACKAGE_BRANCH ; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_TAG | $OS_NAME | GitHub  | Pass |"
    exit 0
fi

echo "BRANCH_NAME = $PACKAGE_BRANCH"
chown -R $USER_NAME:$USER_NAME $USERDIR
cd $PACKAGE_NAME

#checkout to latest version
git checkout v1.5.20.1002
sudo mkdir tmp

cd tmp

#update line 8 of the install-node.sh file by replacing its content with the specified NODE_SHA256 value.
sudo sed -i '8s/.*/NODE_SHA256=25aa3bb52ee6ca29b93dec388c2b5d66265315ffae18be9a8fc2391f656bbe4f/' ../external/node/install-node.sh

#searche for the string "linux-x64.tar.xz" in the install-node.sh file and replace it with "linux-ppc64le.tar.xz"
sudo sed -i 's/linux-x64.tar.xz/linux-ppc64le.tar.xz/'  ../external/node/install-node.sh

sudo ../external/node/install-node.sh
DIR=`pwd`
PATH=$DIR/../bin:$PATH
export PYTHON=`which python3.8`
export PATH=$PYTHON:$PATH

#configure the build system using cmake,
sudo cmake -DCMAKE_INSTALL_PREFIX=/usr/local -DPYTHON="$PYTHON" ../

sudo make
sudo mkdir ../build

#change the current working directory to the parent directory and then execute the npm install
(cd .. && ./bin/npm install)

#install the built files
if !  sudo make install; then
        echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_TAG | $OS_NAME | GitHub | Fail |  Install_Fails"
        exit 1
fi

#Configuration for R-shiny server
sudo mkdir -p /etc/shiny-server
sudo cp ../config/default.config /etc/shiny-server/shiny-server.conf

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

