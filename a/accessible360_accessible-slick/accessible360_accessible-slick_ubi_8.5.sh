#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : accessible-slick
# Version          : 0693e67
# Source repo      : https://github.com/Accessible360/accessible-slick
# Tested on        : RHEL 8.5,UBI 8.5
# Language         : Node
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vathsala . <vaths367@in.ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#   
# ----------------------------------------------------------------------------

PACKAGE_NAME=accessible-slick
#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=${1:-0693e67}
PACKAGE_URL=https://github.com/Accessible360/accessible-slick
yum install -y yum-utils git jq nodejs
npm install -g npm@8.3.0

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

npm install && npm install -g gulp-cli && npm install -g grunt-cli
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "Done build ..."
else
  echo  "Failed build......"
  exit
fi
gulp && grunt
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "Done Test ......"
else
  echo  "Failed Test ......"
fi
