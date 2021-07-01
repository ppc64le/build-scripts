# ----------------------------------------------------------------------------
#
# Package       : lucene-core
# Version       : 9.0
# Source repo   : https://github.com/apache/lucene
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
  export VERSION=main
else
  export VERSION=$1
fi

sudo apt-get update
sudo apt-get install openjdk-11-jdk wget git -y
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-ppc64el/


if [ -d "lucene" ] ; then
  rm -rf lucene
fi
git clone https://github.com/apache/lucene

# Build and Test lucene
cd lucene
git checkout $VERSION

ret=$?

if [ $ret -eq 0 ] ; then
 echo "$Version found to checkout "
else
 echo "$Version not found "
 exit
fi

./gradlew assemble

ret=$?

if [ $ret -ne 0 ] ; then
 echo "Build failed "
 exit
else
./gradlew check
fi
