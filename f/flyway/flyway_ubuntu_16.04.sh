# ----------------------------------------------------------------------------
#
# Package	: flyway
# Version	: flyway-7.8.2
# Source repo	: https://github.com/flyway/flyway
# Tested on	: ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer	: Nageswara Rao K<nagesh4193@gmail.com>/Priya Seth<sethp@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

export REPO=https://github.com/flyway/flyway

if [ -z "$1" ]; then
  export VERSION="flyway-7.8.2"
else
  export VERSION="$1"
fi

# Install dependencies
sudo apt-get update -y
sudo apt-get install -y openjdk-8-jdk maven git
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el
export JRE_HOME=${JAVA_HOME}/jre
export PATH=${JAVA_HOME}/bin:$PATH

if [ -d "flyway" ] ; then
  rm -rf flyway
fi

git clone ${REPO}

## Build and test flyway
cd flyway
git checkout ${VERSION}
ret=$?

if [ $ret -eq 0 ] ; then
  echo "$Version found to checkout "
else
  echo "$Version not found "
  exit
fi

# Fix error compiling: invalid flag
sed '/<release>8/d' pom.xml > tmp
mv tmp pom.xml
mvn clean install
