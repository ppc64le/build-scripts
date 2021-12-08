# ----------------------------------------------------------------------------
#
# Package       : nan
# Version       : v2.15.0
# Source repo   : https://github.com/nodejs/nan
# Tested on     : UBI 8.4
# Script License: Apache License, Version 2 or later
# Maintainer    : Gururaj R Katti <Gururaj.Katti@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

if [ -z "$1" ]; then
  export VERSION=master
else
  export VERSION=$1
fi

if [ -d "nan" ] ; then
  rm -rf nan
fi

# Dependency installation
sudo dnf module install -y nodejs:12
sudo dnf install -y git
sudo dnf install -y wget
sudo dnf install -y make
sudo dnf install -y python2
sudo dnf install -y gcc
sudo dnf install -y gcc-c++
ln -s /usr/bin/python2 /usr/bin/python

# Download the repos
git clone https://github.com/nodejs/nan

# Build and Test nan
cd nan
git checkout $VERSION

ret=$?

if [ $ret -eq 0 ] ; then
 echo "$Version found to checkout "
else
 echo "$Version not found "
 exit
fi

npm install
ret=$?

if [ $ret -ne 0 ] ; then
 echo "Build failed "
 exit
else
 node_modules/.bin/node-gyp rebuild --directory test
 ret=$?
 if [ $ret -ne 0 ] ; then
  echo "Test rebuild failed"
  exit
 else
  node_modules/.bin/tap --gc test/js/*-test.js
  ret=$?
  if [ $ret -ne 0 ] ; then
   echo "Test failed"
  fi
 fi
fi
