#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : R-shiny
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
set -e
USER_NAME=test
USERDIR=/home/test
PACKAGE_NAME=shiny-server
PACKAGE_TAG=${1:-v1.5.20.1002}
PACKAGE_BRANCH=master
PACKAGE_URL=https://github.com/rstudio/shiny-server.git

#Create a non root user
useradd --create-home --home-dir $USERDIR --shell /bin/bash $USER_NAME
usermod -aG wheel $USER_NAME
yum install -y sudo
su $USER_NAME
cd $USERDIR
echo " Current directory: $PWD "

#install required prerequisites
dnf install -y gcc gcc-c++ gcc-gfortran git wget xz cmake make openssl-devel yum-utils wget sudo python39 python39-devel llvm -y

#Install R from Source
dnf config-manager --add-repo http://mirror.centos.org/centos/8-stream/AppStream/ppc64le/os/
dnf config-manager --add-repo http://mirror.centos.org/centos/8-stream/PowerTools/ppc64le/os/
dnf config-manager --add-repo http://mirror.centos.org/centos/8-stream/BaseOS/ppc64le/os/

wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/.
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official

# Required repo to pickup additional EPEL package
dnf install --nodocs -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
dnf install -y R-core R-core-devel libsqlite3x-devel soci-sqlite3 

#Install required dependencies for R
dnf builddep R -y
R_VERSION=$(R --version)
export PATH=$PATH:/opt/R/${R_VERSION}
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
git config --global --add safe.directory $USERDIR/$PACKAGE_NAME
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
