# ------------------------------------------------------------------------------------------
# Package          : zjsonpatch
# Version          : 0.4.11
# Source repo      : https://github.com/flipkart-incubator/zjsonpatch
# Tested on        : ubuntu_18.04
# Passing Arguments: 1.Version of package
# Script License   : Apache License, Version 2 or later
# Maintainer       : Arumugam N S <asellappen@yahoo.com> / Priya Seth<sethp@us.ibm.com>
#
# Disclaimer       : This script has been tested in non-root mode on given
# ==========   platform using the mentioned version of the package.It may not
#              work as expected with newer versions of the package and/or distribution.
#              In such case, please contact "Maintainer" of this script.
#
# ------------------------------------------------------------------------------------------

#!/bin/bash


export REPO=https://github.com/flipkart-incubator/zjsonpatch

#Default tag 0.4.11
if [ -z "$1" ]; then
  export VERSION="0.4.11"
else
  export VERSION="$1"
fi
  
#Testing on jdk8
export JDK="openjdk-8-jdk"

#Default installation
sudo apt-get update
sudo apt-get install -y apt-utils
sudo apt-get install  git npm -y


#For rerunning build
if [ -d "zjsonpatch" ] ; then
  rm -rf zjsonpatch
fi

# run tests with jdk 8
sudo apt-get install -y ${JDK}
jret=$?
if [ $jret -eq 0 ] ; then
  echo "Sucessfully installed JDK  ${JDK} "
else
  echo "Failed to install JDK  ${JDK} "
  exit
fi


sudo apt install  -y maven

#Setting JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-ppc64el/


git clone ${REPO}
cd zjsonpatch
git checkout ${VERSION}
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "${VERSION} found to checkout"
else
  echo  "${VERSION} not found"
  exit
fi


mvn -v

#required  javadoc to create javadoc.jar from pom.xml
npm install -s javadoc

#to avoid passphrase in batch mode for sign-artifacts
grep -v '<goal>sign</goal>' pom.xml>/tmp/pom.xml
mv /tmp/pom.xml pom.xml

#Build and test zjsonpatch
sudo mvn clean install -DskipTests=true -B -V
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "Done build ......"
else
  echo  "Failed build ....."
  exit
fi

mvn test -B
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "Done Test ......"
else
  echo  "Failed Test ......"
fi
