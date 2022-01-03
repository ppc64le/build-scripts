# ----------------------------------------------------------------------------
#
# Package       : bcprov-ext-jdk15on
# Version       : r1rv69 
# Source repo   : https://github.com/bcgit/bc-java
# Tested on     : UBI: 8.3
# Script License: Apache License 2.0
# Maintainer's  : Balavva Mirji <Balavva.Mirji@ibm.com>
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

# Variables
REPO=https://github.com/bcgit/bc-java

# Default tag for bcprov-ext-jdk15on
if [ -z "$1" ]; then
  export VERSION="r1rv69"
else
  export VERSION="$1"
fi

# install tools and dependent packages
yum update -y
yum install -y git wget unzip 

# install java
yum install -y java-1.8.0-openjdk-devel

# install gradle
wget https://services.gradle.org/distributions/gradle-6.7.1-bin.zip
unzip gradle-6.7.1-bin.zip
mkdir /opt/gradle
cp -pr gradle-6.7.1/* /opt/gradle
export PATH=/opt/gradle/bin:${PATH}

#Cloning Repo
git clone $REPO
cd ./bc-java/prov
git checkout ${VERSION}

#Build and test package
gradle build
gradle test 







