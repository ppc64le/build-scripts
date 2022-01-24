# ----------------------------------------------------------------------------
#
# Package       : bcprov-jdk15on
# Version       : r1rv61
# Source repo   : https://github.com/bcgit/bc-java
# Tested on     : UBI: 8.3
# Script License: Apache License 2.0
# Maintainer's  : Srividya Chittiboina <Srividya.Chittiboina@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

set -e

REPO=https://github.com/bcgit/bc-java

# Default tag for bcprov-ext-jdk15on
if [ -z "$1" ]; then
  export VERSION="r1rv61"
else
  export VERSION="$1"
fi

yum update -y
yum install -y git wget unzip
yum install -y java-1.8.0-openjdk-devel

# install gradle
wget https://downloads.gradle-dn.com/distributions/gradle-3.3-all.zip
unzip -d /opt/gradle gradle-3.3-all.zip
ls /opt/gradle/gradle-3.3/
export PATH=$PATH:/opt/gradle/gradle-3.3/bin

#Cloning Repo
git clone $REPO
cd bc-java
git checkout ${VERSION}
cd prov

#Build and test package
gradle build
gradle test 

