# ----------------------------------------------------------------------------
#
# Package       : hibernate-core
# Version       : 6.0.0Alpha5
# Source repo   : https://github.com/hibernate/hibernate-orm.git
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

export REPO=https://github.com/hibernate/hibernate-orm.git

#Default tag Generex
if [ -z "$1" ]; then
  export VERSION="6.0.0.Alpha5"
else
  export VERSION="$1"
fi

yum update -y
yum install git -y

yum install java-1.8.0-openjdk-devel
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.292.b10-1.el8_4.ppc64le
export PATH=$PATH:$JAVA_HOME/bin
git clone ${REPO}
git checkout ${VERSION}
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "${VERSION} found to checkout"
else
  echo  "${VERSION} not found"
  exit
fi
cd hibernate-orm

./gradlew
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "Done build ..."
else
  echo  "Failed build......"
  exit
fi

./gradle hibernate-core:test
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "Done Test ......"
else
  echo  "Failed Test ......"
fi


