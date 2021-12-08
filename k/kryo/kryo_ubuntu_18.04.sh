# ----------------------------------------------------------------------------
#
# Package          : kryo
# Version          : 5.0.4
# Source repo      : https://github.com/EsotericSoftware/kryo
# Tested on        : ubuntu_18.04
# Passing Arguments: 1.Version of package, 2.JDK version (openjdk-8-jdk or openjdk-11-jdk)
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


export REPO=https://github.com/EsotericSoftware/kryo

if [ -z "$1" ]; then
  export VERSION="kryo-parent-5.0.4"
else
  export VERSION="$1"
fi

#Default testing on jdk8
if [ -z "$2" ]; then
  export JDK="openjdk-8-jdk"
else
  export JDK="$2"
fi


sudo apt-get update
sudo apt-get install wget git -y

if [ -d "kryo" ] ; then
  rm -rf kryo
fi


git clone ${REPO}


## Build and test kryo
cd kryo
git checkout ${VERSION}
ret=$?

if [ $ret -eq 0 ] ; then
  echo "$Version found to checkout "
else
  echo "$Version not found "
  exit
fi

sudo apt install  -y maven


# run tests with java 11 or jdk 8
sudo apt-get install -y ${JDK}
jret=$?
if [ $jret -eq 0 ] ; then
  echo "Sucessfully installed $JDK "
else
  echo "Failed to install $JDK "
  exit
fi


#Setting JAVA_HOME
export folder=`echo ${JDK}  | grep -oP '(?<=openjdk-).*(?=-jdk)'`
export JAVA_HOME=/usr/lib/jvm/java-${folder}-openjdk-ppc64el/

mvn -v

## Build and test kryo
cd kryo
sudo mvn install -DskipTests=true -B -V
mvn test -B
