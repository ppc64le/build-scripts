# ----------------------------------------------------------------------------
#
# Package       : jacoco core
# Version       : 0.7.2-SNAPSHOT
# Source repo   : https://github.com/jacoco/jacoco.git
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
export REPO=https://github.com/jacoco/jacoco.git

#Default tag Generex
if [ -z "$1" ]; then
  export VERSION="0.7.2-SNAPSHOT"
else
  export VERSION="$1"
fi

yum update -y
yum install git maven -y
git clone ${REPO}
cd jacoco/org.jacoco.core
git checkout ${VERSION}
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "${VERSION} found to checkout"
else
  echo  "${VERSION} not found"
  exit
fi
mvn install
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "Done build and test..."
else
  echo  "Failed build......"
  exit
fi
