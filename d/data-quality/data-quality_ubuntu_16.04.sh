# ----------------------------------------------------------------------------
#
# Package		: data-quality
# Version		: 8.0.10
# Source repo	: https://github.com/Talend/data-quality.git
# Tested on		: ubuntu_16.04
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
# !/bin/bash

export REPO=https://github.com/Talend/data-quality.git

if [ -z "$1" ]; then
  export VERSION="8.0.10"
else
  export VERSION="$1"
fi

# Install dependencies
sudo apt-get update -y
sudo apt-get install -y openjdk-8-jdk maven git  
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el
export JRE_HOME=${JAVA_HOME}/jre
export PATH=${JAVA_HOME}/bin:$PATH

if [ -d "data-quality" ] ; then
  rm -rf data-quality
fi

git clone ${REPO}

## Build and test data-quality
cd data-quality
git checkout ${VERSION}
ret=$?

if [ $ret -eq 0 ] ; then
  echo "$Version found to checkout "
else
  echo "$Version not found "
  exit
fi

mvn clean install
