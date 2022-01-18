# ----------------------------------------------------------------------------
#
# Package               : jetty-test-helper
# Version               : jetty-test-helper-5.3
# Source repo           : https://github.com/eclipse/jetty.toolchain
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
  export PACKAGE_VERSION=jetty-test-helper-5.3
else
  export PACKAGE_VERSION=$1
fi
if [ -d "jetty.toolchain" ] ; then
  rm -rf jetty.toolchain
fi

# Dependency installation
dnf install -y git java-1.8.0-openjdk-devel maven

# Download the repos
git clone https://github.com/eclipse/jetty.toolchain.git

# Checkout version
cd jetty.toolchain
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
