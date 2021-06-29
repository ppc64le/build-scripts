# ----------------------------------------------------------------------------
#
# Package       : jsr-305
# Source repo   : https://github.com/amaembo/jsr-305
# Tested on     : Ubuntu_18.04
# Script License: Apache License, Version 2 or later
# Maintainer    : Kishor Kunal Raj <kishore.kunal.mr@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

export REPO=https://github.com/amaembo/jsr-305
export JDK="openjdk-8-jdk"

#Default tag V2.9
if [ -z "$1" ]; then
  export VERSION="master"
else
  export VERSION="$1"
fi

#Default installation
sudo apt update -y
sudo apt install maven git -y

sudo apt-get install -y ${JDK}
jret=$?
if [ $jret -eq 0 ] ; then
  echo "Sucessfully installed JDK  ${JDK} "
else
  echo "Failed to install JDK  ${JDK} "
  exit
fi

#For rerunning build
if [ -d "jsr-305" ] ; then
  rm -rf jsr-305
fi

git clone ${REPO}
cd jsr-305
git checkout ${VERSION}
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "${VERSION} found to checkout"
else
  echo  "${VERSION} not found"
  exit
fi

#Running build and tests
mvn eclipse:clean eclipse:eclipse
mvn idea:idea
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "Build successful, log and jar file created....."
else
  echo  "Failed to  build......"
  exit
fi

