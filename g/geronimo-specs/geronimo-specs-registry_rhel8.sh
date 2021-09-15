# ----------------------------------------------------------------------------
#
# Package       : geronimo-specs
# Version       : 1.0
# Source repo   : https://github.com/apache/geronimo-specs.git
# Tested on     : RHEL8
# Script License: Apache License, Version 2 or later
# Maintainer    : Narasimha udala<narasimha.rao.udala@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

export REPO=https://github.com/apache/geronimo-specs.git

#Default tag Generex
if [ -z "$1" ]; then
  export VERSION="1.0"
else
  export VERSION="$1"
fi 

yum update -y
yum install wget git -y

yum install -y java-1.8.0-openjdk-devel
yum install -y maven

git clone ${REPO}
cd geronimo-servlet_3.0_spec
git checkout ${VERSION}
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "${VERSION} found to checkout"
else
  echo  "${VERSION} not found"
  exit
fi


mvn install -Dskiptests
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "Done build ..."
else
  echo  "Failed build......"
  exit
fi
mvn test
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "Done Test ......"
else
  echo  "Failed Test ......"
fi
