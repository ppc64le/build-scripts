# ----------------------------------------------------------------------------
#
# Package               : shiro
# Version               : shiro-root-1.5.2
# Source repo           : https://github.com/apache/shiro
# Tested on             : UBI 8.4
# Language              : Java
# Travis-Check          : True
# Script License        : Apache License, Version 2 or later
# Maintainer            : Vikas <kumar.vikas@in.ibm.com>
#
# Disclaimer            : This script has been tested in root mode on given
# ==========              platform using the mentioned version of the package.
#                         It may not work as expected with newer versions of the
#                         package and/or distribution. In such case, please
#                         contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

set -e

if [ -z "$1" ]; then
  export PACKAGE_VERSION=shiro-root-1.5.2
else
  export PACKAGE_VERSION=$1
fi
if [ -d "shiro" ] ; then
  rm -rf shiro
fi

# Dependency installation
dnf install -y git java-1.8.0-openjdk-devel maven

# Download the repos
git clone https://github.com/apache/shiro.git

# Checkout version
cd shiro
git checkout $PACKAGE_VERSION
ret=$?
if [ $ret -eq 0 ] ; then
 echo "$PACKAGE_VERSION found to checkout "
else
 echo "$PACKAGE_VERSION not found "
 exit
fi

mvn -e -Pci,docs install apache-rat:check -B
ret=$?
if [ $ret -ne 0 ] ; then
  echo "Build & unit tests failed "
else
  echo "Build & unit tests successful "
fi
