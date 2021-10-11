# ----------------------------------------------------------------------------
#
# Package           : jboss-marshalling
# Version           : 2.0.12.Final
# Source repo       : https://github.com/jboss-remoting/jboss-marshalling
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


export REPO=https://github.com/jboss-remoting/jboss-marshalling

if [ -z "$1" ]; then
  export VERSION="2.0.12.Final"
else
  export VERSION="$1"
fi

sudo apt-get update
sudo apt-get install openjdk-9-jdk wget git -y
sudo apt install  -y maven
mvn -version

if [ -d "jboss-marshalling" ] ; then
  rm -rf jboss-marshalling
fi

git clone ${REPO}

## Build and test jboss-marshalling
cd jboss-marshalling
git checkout ${VERSION}
ret=$?

if [ $ret -eq 0 ] ; then
  echo "$Version found to checkout "
else
  echo "$Version not found "
  exit
fi

mvn clean install
