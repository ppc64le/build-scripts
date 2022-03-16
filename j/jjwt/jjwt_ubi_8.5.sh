#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : jjwt
# Version       : f6d0679
# Source repo   : https://github.com/jwtk/jjwt
# Tested on     : UBI 8.5
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Vathsala . <vaths367@in.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=jjwt
#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=${1:-f6d0679}
PACKAGE_URL=https://github.com/jwtk/jjwt


# Dependency installation
dnf install -y git java-1.8.0-openjdk-devel maven

# Download the repos
git clone https://github.com/jwtk/jjwt

# Checkout version
cd jjwt
git checkout $PACKAGE_VERSION
ret=$?
if [ $ret -eq 0 ] ; then
 echo "$PACKAGE_VERSION found to checkout "
else
 echo "$PACKAGE_VERSION not found "
 exit
fi

mvn install -DskipTests=true
ret=$?
if [ $ret -ne 0 ] ; then
  echo "Build failed "
else
  mvn test
  ret=$?
  if [ $ret -ne 0 ] ; then
    echo "Tests failed "
  else
    echo "Build & unit tests Successful "
  fi
fi


