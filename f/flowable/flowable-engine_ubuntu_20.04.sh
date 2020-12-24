# ----------------------------------------------------------------------------
#
# Package           : flowable-engine
# Version           : 6.6.0
# Source repo       : https://github.com/flowable/flowable-engine
# Tested on         : ubuntu_20.04
# Script License    : Apache License, Version 2 or later
# Maintainer        : Santosh Kulkarni <santoshkulkarni70@gmail.com> / Priya Seth<sethp@us.ibm.com>
#
# Disclaimer        : This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash


export REPO=https://github.com/flowable/flowable-engine

if [ -z "$1" ]; then
  export VERSION="flowable-6.6.0"
else
  export VERSION="$1"
fi

sudo apt-get update
sudo apt-get install openjdk-8-jdk wget git -y
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-ppc64el/
sudo apt install  -y maven
mvn -version

if [ -d "flowable-engine" ] ; then
  rm -rf flowable-engine
fi

git clone ${REPO}

## Build and test flowable-engine
cd flowable-engine
git checkout ${VERSION}
ret=$?

if [ $ret -eq 0 ] ; then
  echo "$Version found to checkout "
else
  echo "$Version not found "
  exit
fi

sudo mvn clean:clean install -DskipTests=true -B -V
