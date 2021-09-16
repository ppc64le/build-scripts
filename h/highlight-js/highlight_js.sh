# ----------------------------------------------------------------------------
#
# Package       : highlight.js
# Version       : 11.2.0
# Source repo   : https://github.com/highlightjs/highlight.js.git
# Tested on     : RHEL8
# Script License: Apache License, Version 2 or later
# Maintainer    : Narasimha udala <narasimha.rao.udala@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

export REPO=https://github.com/highlightjs/highlight.js.git

#Default tag Generex
if [ -z "$1" ]; then
  export VERSION="11.2.0"
else
  export VERSION="$1"
fi

yum update -y
yum install git -y
dnf module install nodejs:14 
#Error: Cannot find module 'commander'
npm install commander --save

git clone ${REPO}
cd /highlight.js
git checkout ${VERSION}
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "${VERSION} found to checkout"
else
  echo  "${VERSION} not found"
  exit
fi

npm run build
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "Done build ..."
else
  echo  "Failed build......"
  exit
fi
npm run test
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "Done Test ......"
else
  echo  "Failed Test ......"
fi





