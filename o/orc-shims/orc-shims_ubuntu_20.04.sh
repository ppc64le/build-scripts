# ----------------------------------------------------------------------------
#
# Package       : shims
# Version       : 1.6
# Source repo   : https://github.com/apache/orc/tree/master/java/shims
# Tested on     : ubuntu_20.04
# Script License: Apache License, Version 2 or later
# Maintainer    : Gururaj R Katti <Gururaj.Katti@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

if [ -z "$1" ]; then
  export VERSION="1.6.7"
else
  export VERSION="$1"
fi

sudo apt-get update
sudo apt-get install openjdk-8-jdk wget git -y
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-ppc64el/

wget http://www-eu.apache.org/dist/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz
tar xzvf apache-maven-3.6.3-bin.tar.gz
export PATH=$PATH:`pwd`/apache-maven-3.6.3/bin

if [ -d "orc" ] ; then
  rm -rf orc
fi
git clone https://github.com/apache/orc

# Build and Test shims
cd orc/java/shims
git checkout -b $VERSION rel/release-$VERSION
ret=$?

if [ $ret -eq 0 ] ; then
  echo "$Version found to checkout "
else
  echo "$Version not found "
  exit
fi

mvn clean install
