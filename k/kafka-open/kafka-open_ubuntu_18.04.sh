# ----------------------------------------------------------------------------
#
# Package          : kafka-open
# Version          : 2.9
# Source repo      : https://github.com/odpi/egeria
# Tested on        : ubuntu_18.04
# Passing Arguments: Passing Arguments: 1.Version of package
# Script License   : Apache License, Version 2 or later
# Maintainer       : Arumugam N S <asellappen@yahoo.com> / Priya Seth<sethp@us.ibm.com>
#
# Disclaimer       : This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

export REPO=https://github.com/odpi/egeria

#Default tag V2.9
if [ -z "$1" ]; then
  export VERSION="V2.9"
else
  export VERSION="$1"
fi

#Testing on jdk8
export JDK="openjdk-8-jdk"

#Default installation
sudo apt-get update
sudo apt-get install git -y

#For rerunning build
if [ -d "egeria" ] ; then
  rm -rf egeria
fi

# run and ests jdk 8
sudo apt-get install -y ${JDK}
jret=$?
if [ $jret -eq 0 ] ; then
  echo "Sucessfully installed JDK  ${JDK} "
else
  echo "Failed to install JDK  ${JDK} "
  exit
fi

#Setting JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-ppc64el/


sudo apt install  -y maven

mvn -v


git clone ${REPO}
cd egeria
git checkout ${VERSION}
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "${VERSION} found to checkout"
else
  echo  "${VERSION} not found"
  exit
fi

#goto kafka-open-metadata-topic-connector path

cd open-metadata-implementation/adapters/open-connectors/event-bus-connectors/open-metadata-topic-connectors/kafka-open-metadata-topic-connector
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "Path found in the package to build and started building ..."
else
  echo  "Path  not found in the package ..."
  exit
fi
pwd
sudo mvn clean install -DskipTests=true -B -V
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
