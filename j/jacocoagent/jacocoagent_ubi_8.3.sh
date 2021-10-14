# ----------------------------------------------------------------------------
#
# Package       : jacocoagent
# Version       : v0.7.2
# Source repo   : https://github.com/jacoco/jacoco
# Tested on     : ubi: 8.3
# Script License: Apache License 2.0
# Maintainer's  : Hari Pithani <Hari.Pithani@ibm.com>
#
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

read -p "Enter Release_Version : " REL_VER

#Default tag jacoco
if [ -z "$REL_VER" ]; then
  export VERSION="v0.7.2"
else
  export VERSION="$REL_VER"
fi

#Default installation
yum update -y
yum install git maven -y

#For rerunning build
if [ -d "jacoco" ] ; then
  rm -rf jacoco
fi

git clone ${REPO}
cd jacoco
git checkout ${VERSION}
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "${VERSION} found to checkout"
else
  echo  "${VERSION} not found"
  exit
fi

mvn install -DskipTests

cd org.jacoco.agent
mvn install -DskipTests
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "Done build ..."
else
  echo  "Failed build......"
  exit
fi

mvn test -B
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "Done Test ......"
else
  echo  "Failed Test ......"
fi