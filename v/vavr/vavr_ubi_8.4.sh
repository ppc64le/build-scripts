#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package               : vavr
# Version               : vavr-1.0.0-alpha-4
# Source repo           : https://github.com/vavr-io/vavr.git
# Tested on             : UBI 8.4
# Language              : Java
# Travis-Check          : True
# Script License        : Apache License, Version 2 or later
# Maintainer            : Vikas . <kumar.vikas@in.ibm.com>
#
# Disclaimer            : This script has been tested in root mode on given
# ==========              platform using the mentioned version of the package.
#                         It may not work as expected with newer versions of the
#                         package and/or distribution. In such case, please
#                         contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

export PACKAGE_NAME=vavr
export PACKAGE_URL=https://github.com/vavr-io/vavr.git

if [ -z "$1" ]; then
  export PACKAGE_VERSION=vavr-1.0.0-alpha-4
else
  export PACKAGE_VERSION=$1
fi
if [ -d "${PACKAGE_NAME}" ] ; then
  rm -rf ${PACKAGE_NAME}
fi


yum install -y java-1.8.0-openjdk-devel git

git clone ${PACKAGE_URL} ${PACKAGE_NAME}
cd ${PACKAGE_NAME}
git checkout ${PACKAGE_VERSION}
ret=$?
if [ $ret -eq 0 ] ; then
  echo "Version $PACKAGE_VERSION found to checkout "
else
  echo "Version $PACKAGE_VERSION not found "
  exit
fi

if [ ! -d ~/.gradle ]
then
mkdir ~/.gradle
fi

echo "ossrhUsername=dummy">>~/.gradle/gradle.properties
echo "ossrhPassword=dummy">>~/.gradle/gradle.properties

./gradlew check --info
ret=$?
if [ $ret -ne 0 ] ; then
  echo "Build failed "
else
  ./gradlew assemble --info
  ret=$?
  if [ $ret -ne 0 ] ; then
    echo "Test failed "
  else
    echo "Build & Test Successful "
  fi
fi
