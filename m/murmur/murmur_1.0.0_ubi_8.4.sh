# ----------------------------------------------------------------------------
#
# Package               : murmur
# Version               : murmur-1.0.0
# Source repo           : https://github.com/sangupta/murmur/
# Tested on             : UBI 8.4
# Language              : Java
# Travis-Check          : False
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
  export PACKAGE_VERSION=murmur-1.0.0
else
  export PACKAGE_VERSION=$1
fi
if [ -d "murmur" ] ; then
  rm -rf murmur
fi

# Dependency installation
dnf install -y git java-1.8.0-openjdk-devel maven

# Download the repos
git clone https://github.com/sangupta/murmur.git

# Checkout version
cd murmur
git checkout $PACKAGE_VERSION
ret=$?
if [ $ret -eq 0 ] ; then
 echo "$PACKAGE_VERSION found to checkout "
else
 echo "$PACKAGE_VERSION not found "
 exit
fi

mvn install -DskipTests=true -B -V
ret=$?
if [ $ret -ne 0 ] ; then
  echo "Build failed "
else
  mvn test -B
  ret=$?
  if [ $ret -ne 0 ] ; then
    echo "Tests failed "
  else
    echo "Build & unit tests Successful "
  fi
fi
