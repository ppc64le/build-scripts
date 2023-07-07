#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : jquery.easing
# Version          : c05e039
# Source repo      : https://github.com/gdsmith/jquery.easing
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

PACKAGE_NAME=jquery.easing
#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=${1:-c05e039}
PACKAGE_URL=https://github.com/gdsmith/jquery.easing
yum install -y yum-utils git jq nodejs
npm install -g npm@8.3.0

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Tests not available(Test N/A) 

npm install && npm run build
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "Done build ..."
else
  echo  "Failed build......"
  exit
fi
