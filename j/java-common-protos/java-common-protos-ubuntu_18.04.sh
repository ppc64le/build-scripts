# ----------------------------------------------------------------------------
#
# Package       : java-common-protos
# Version       : 2.3.2
# Source repo   : https://github.com/googleapis/java-common-protos
# Tested on     : Ubuntu_18.04
# Passing Arguments: 1.Version of package, 2.JDK version (openjdk-8-jdk or openjdk-11-jdk)# Script License: Apache License, Version 2 or later
# Script License   : Apache License, Version 2 or later
# Maintainer    : Kishor Kunal Raj <kishore.kunal.mr@ibm.com> / Priya Seth<sethp@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#/bin/bash

export REPO=https://github.com/googleapis/java-common-protos

#Default tag v2.3.2
if [ -z "$1" ]; then
  export VERSION="v2.3.2"
else
  export VERSION="$1"
fi


#Default testing on jdk8
if [ -z "$2" ]; then
  export JDK="openjdk-8-jdk"
else
  export JDK="$2"
fi


#Default installation
sudo apt-get update
sudo apt-get install -y apt-utils
sudo apt-get install  git -y


#From rerunning build
if [ -d "flowable-engine" ] ; then
  rm -rf flowable-engine
fi

# run tests with java 11 or jdk 8
sudo apt-get install -y ${JDK}
jret=$?
if [ $jret -eq 0 ] ; then
  echo "Sucessfully installed JDK  ${JDK} "
else
  echo "Failed to install JDK  ${JDK} "
  exit
fi

#Setting JAVA_HOME
export folder=`echo ${JDK}  | grep -oP '(?<=openjdk-).*(?=-jdk)'`
export JAVA_HOME=/usr/lib/jvm/java-${folder}-openjdk-ppc64el/


sudo apt install  -y maven
mvn -v

git clone ${REPO}
cd java-common-protos
git checkout ${VERSION}
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "${VERSION} found to checkout"
else
  echo  "${VERSION} not found"
  exit
fi

#Build and test java-common-protos module
mvn clean verify
ret=$?
    if [ $ret -eq 0 ] ; then
      echo  "Done build for java-common-protos ......"
    else
      echo  "Failed build for java-common-protos ......"
      cd ..
      continue
    fi

export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service/account.json
mvn -Penable-integration-tests clean verify
 ret=$?
    if [ $ret -eq 0 ] ; then
      echo  "Done Test for java-common-protos ......"
    else
      echo  "Failed Test for java-common-protos......"
    fi
    #back to module path
    cd ..
echo "Completed building and testing  java-common-protos ................\n "

