# ----------------------------------------------------------------------------
#
# Package        : Generex
# Version        : 1.0.2
# Source repo    : https://github.com/mifmif/Generex
# Tested on      : ubuntu_16.04
# Script License : Apache License, Version 2 or later
# Maintainer     : devendranath.thadi3@gmail.com / Priya Seth<sethp@us.ibm.com>
#
# Disclaimer     : This script has been tested in non-root mode on given
# ==========       platform using the mentioned version of the package.
#                  It may not work as expected with newer versions of the
#                  package and/or distribution. In such case, please
#                  contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash


export REPO=https://github.com/mifmif/Generex.git

#Default tag Generex
if [ -z "$1" ]; then
  export VERSION="1.0.2"
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
apt-get update
apt-get install -y apt-utils
apt-get install  git -y

#Fro rerunning build
if [ -d "Generex" ] ; then
  rm -rf Generex
fi

# run tests with java 11 or jdk 8
apt-get install -y ${JDK}
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


apt install  -y maven

mvn -v


git clone ${REPO}
cd Generex
git checkout ${VERSION}
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "${VERSION} found to checkout"
else
  echo  "${VERSION} not found"
  exit
fi

mvn clean install -DskipTests=true -B -V
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
