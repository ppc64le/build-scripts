# ----------------------------------------------------------------------------
#
# Package       : spring-data-commons
# Version       : 2.6.0-M2
# Source repo   : https://github.com/spring-projects/spring-data-commons.git
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

export REPO=https://github.com/spring-projects/spring-data-commons.git

#Default tag Generex
if [ -z "$1" ]; then
  export VERSION="2.6.0-M2"
else
  export VERSION="$1"
fi
yum update -y
yum install git maven -y
yum install java-1.8.0-openjdk-devel
git clone ${REPO}
cd spring-data-commons
git checkout ${VERSION}
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "${VERSION} found to checkout"
else
  echo  "${VERSION} not found"
  exit
fi
./mvnw clean install
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "Done Build and Test ......"
else
  echo  "Failed Test ......"
fi