#!/bin/bash -e

# ----------------------------------------------------------------------------
# Package          : sphinx
# Version          : v4.5.0
# Source repo      : https://github.com/sphinx-doc/sphinx
# Tested on        : UBI 8.5
# Language         : Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Bhagat Singh <Bhagat.singh1@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#   
# ----------------------------------------------------------------------------

# Variables
PACKAGE_NAME=sphinx
PACKAGE_URL=https://github.com/sphinx-doc/sphinx
#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=${1:-v4.5.0}

 #Dependencies
 yum install -y python3 python3-devel ncurses git gcc gcc-c++ libffi libffi-devel sqlite sqlite-devel sqlite-libs python3-pytest make cmake wget cargo rust openssl-devel graphviz
 
 #Imagemagick support for image processing
 dnf install https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/LibRaw-0.19.5-3.el8.ppc64le.rpm -y
 dnf install https://rpmfind.net/linux/epel/8/Everything/ppc64le/Packages/l/libraqm-0.7.0-4.el8.ppc64le.rpm -y
 dnf install https://rpmfind.net/linux/epel/8/Everything/ppc64le/Packages/i/ImageMagick-libs-6.9.10.86-1.el8.ppc64le.rpm -y 
 dnf install https://rpmfind.net/linux/epel/8/Everything/ppc64le/Packages/i/ImageMagick-6.9.10.86-1.el8.ppc64le.rpm  -y

 OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

#Check if package exists
if [ -d "$PACKAGE_NAME" ] ; then
      rm -rf $PACKAGE_NAME
  echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Removed existing package if any"  
fi
 
# Cloning the repository from remote to local
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

python3 setup.py install 
pip3 install html5lib
python3 -m pip install mypy
pip3 install -U pip setuptools

if ! make build PYTHON=/usr/bin/python3; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi
if !  make test PYTHON=/usr/bin/python3 TEST="--junitxml=test-reports/pytest/results.xml -vv"; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi 
